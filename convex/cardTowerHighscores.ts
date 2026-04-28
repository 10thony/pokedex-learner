import { v } from "convex/values";
import { mutation, query } from "./_generated/server";

const MAX_LEADERBOARD = 10;
const MIN_SCORE = 0;

function toPublicRow(row: {
  _id: unknown;
  name: string;
  score: number;
  cards: number;
  rows: number;
}) {
  return {
    name: row.name,
    score: row.score,
    cards: row.cards,
    rows: row.rows
  };
}

export const list = query({
  args: {},
  handler: async (ctx) => {
    const rows = await ctx.db
      .query("cardTowerHighscores")
      .withIndex("by_score", (q) => q.gte("score", MIN_SCORE))
      .order("desc")
      .take(MAX_LEADERBOARD);
    return rows.map(toPublicRow);
  }
});

export const submit = mutation({
  args: {
    name: v.string(),
    score: v.number(),
    cards: v.number(),
    rows: v.number()
  },
  handler: async (ctx, args) => {
    const name = String(args.name || "")
      .trim()
      .slice(0, 20) || "Player";
    if (!Number.isFinite(args.score) || !Number.isFinite(args.cards) || !Number.isFinite(args.rows)) {
      throw new Error("Invalid score data");
    }
    const score = Math.floor(Number(args.score));
    const cards = Math.floor(Number(args.cards));
    const rows = Math.floor(Number(args.rows));
    if (cards < 0 || rows < 0) {
      throw new Error("Invalid score data");
    }

    await ctx.db.insert("cardTowerHighscores", {
      name,
      score,
      cards,
      rows
    });

    const ranked = await ctx.db
      .query("cardTowerHighscores")
      .withIndex("by_score", (q) => q.gte("score", MIN_SCORE))
      .order("desc")
      .collect();

    const overflow = ranked.slice(MAX_LEADERBOARD);
    for (const doc of overflow) {
      await ctx.db.delete(doc._id);
    }

    return ranked.slice(0, MAX_LEADERBOARD).map(toPublicRow);
  }
});
