/* eslint function-paren-newline:0 */

import Joi from 'joi';

import { REGION_TYPES } from '@/constants';

const barrierSchema = Joi.object({
  id: Joi.string(),
  x_coord: Joi.number(),
  y_coord: Joi.number(),
  effect: Joi.number(),
  effect_ln: Joi.number(),
  delta: Joi.number(),
  surveyed: Joi.boolean(),
  aquatic: Joi.number(),
  type: Joi.string().allow(['culvert', 'dam']),
  lat: Joi.number(),
  lon: Joi.number(),
  node_id: Joi.string().allow(null)
});

const scenarioSchema = Joi.object({
  id: Joi.number(),
  status: Joi.string().allow(['finished', 'failed']),
  barriers: Joi.array().items(barrierSchema),
  results: Joi.object().optional({
    effect: Joi.number(),
    delta: Joi.number()
  })
});

const minimal = Joi.object({
  version: Joi.number().integer().min(1).required()
}).unknown();

const full = Joi.object({
  version: Joi.number().integer().min(1),
  project: Joi.object({
    name: Joi.string().required(),
    description: Joi.string().empty(''),
    author: Joi.string().empty(''),
    created: Joi.number().integer()
  }),
  region: Joi.object({
    type: Joi.string().allow(REGION_TYPES.map(d => d.value)),
    feature: Joi.object({
      type: Joi.string().allow('Feature'),
      properties: Joi.object(),
      geometry: Joi.object({
        type: Joi.string().allow('Polygon'),
        coordinates: Joi.array().length(1)
          .items(
            Joi.array().min(2).items(
              Joi.array().length(2).items(Joi.number())
            )
          )
      })
    })
  }),
  barriers: Joi.array().items(barrierSchema),
  scenarios: Joi.array().items(scenarioSchema)
});

export default { full, minimal };
