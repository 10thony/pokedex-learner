import { paginationOptsValidator } from "convex/server";
import { v } from "convex/values";
import { mutation, query } from "./_generated/server";

export const listByType = query({
  args: {
    type1: v.string(),
    paginationOpts: paginationOptsValidator
  },
  handler: async (ctx, args) => {
    return ctx.db
      .query("pokedex")
      .withIndex("by_type1_and_name", (q) => q.eq("type1", args.type1))
      .paginate(args.paginationOpts);
  }
});

export const getByDexNumber = query({
  args: { dexNumber: v.number() },
  handler: async (ctx, args) => {
    return ctx.db
      .query("pokedex")
      .withIndex("by_dex_number", (q) => q.eq("dexNumber", args.dexNumber))
      .unique();
  }
});

export const listDeck = query({
  args: {
    limit: v.optional(v.number())
  },
  handler: async (ctx, args) => {
    const safeLimit = Math.max(1, Math.min(151, Math.floor(Number(args.limit ?? 151))));
    const entries = await ctx.db.query("pokedex").take(1000);
    const normalized = entries
      .map((entry) => {
        const dexNumber = Number(entry.dexNumber ?? entry.national_number ?? 0);
        const name = String(entry.name ?? entry.english_name ?? "");
        const type1 = String(entry.type1 ?? entry.primary_type ?? "");
        const type2Raw = entry.type2 ?? entry.secondary_type ?? null;
        const type2 = type2Raw ? String(type2Raw) : null;
        return { dexNumber, name, type1, type2 };
      })
      .filter((entry) => Number.isFinite(entry.dexNumber) && entry.dexNumber > 0 && entry.name && entry.type1)
      .sort((a, b) => a.dexNumber - b.dexNumber);
    return normalized.slice(0, safeLimit);
  }
});

export const dedupeByNameMigration = mutation({
  args: {
    dryRun: v.optional(v.boolean())
  },
  handler: async (ctx, args) => {
    const allPokemon = await ctx.db.query("pokedex").collect();
    const keepByName = new Map<string, { _id: (typeof allPokemon)[number]["_id"]; dexNumber: number }>();
    const toDelete: Array<(typeof allPokemon)[number]["_id"]> = [];

    allPokemon.forEach((pokemon) => {
      const normalizedName = String(pokemon.name || "").trim().toLowerCase();
      if (!normalizedName) {
        return;
      }
      const existing = keepByName.get(normalizedName);
      const currentDex = Number(pokemon.dexNumber || Number.POSITIVE_INFINITY);
      if (!existing) {
        keepByName.set(normalizedName, { _id: pokemon._id, dexNumber: currentDex });
        return;
      }
      if (currentDex < existing.dexNumber) {
        toDelete.push(existing._id);
        keepByName.set(normalizedName, { _id: pokemon._id, dexNumber: currentDex });
      } else {
        toDelete.push(pokemon._id);
      }
    });

    if (!args.dryRun) {
      for (const id of toDelete) {
        await ctx.db.delete(id);
      }
    }

    return {
      dryRun: Boolean(args.dryRun),
      scanned: allPokemon.length,
      deleted: toDelete.length,
      uniqueNames: keepByName.size
    };
  }
});
