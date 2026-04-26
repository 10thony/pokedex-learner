import { paginationOptsValidator } from "convex/server";
import { v } from "convex/values";
import { query } from "./_generated/server";

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
