import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  pokedex: defineTable({
    dexNumber: v.number(),
    name: v.string(),
    type1: v.string(),
    type2: v.optional(v.union(v.string(), v.null())),
    generation: v.optional(v.union(v.number(), v.null())),
    hp: v.optional(v.union(v.number(), v.null())),
    attack: v.optional(v.union(v.number(), v.null())),
    defense: v.optional(v.union(v.number(), v.null())),
    specialAttack: v.optional(v.union(v.number(), v.null())),
    specialDefense: v.optional(v.union(v.number(), v.null())),
    speed: v.optional(v.union(v.number(), v.null()))
  })
    .index("by_dex_number", ["dexNumber"])
    .index("by_name", ["name"])
    .index("by_type1_and_name", ["type1", "name"])
    .index("by_generation_and_dex_number", ["generation", "dexNumber"])
});
