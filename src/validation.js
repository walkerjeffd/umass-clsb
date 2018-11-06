import Joi from 'joi';

import { VERSION } from '@/constants';
import * as errors from '@/errors';
import schema from '@/schema';

// eslint-disable-next-line
export function validateProject(project) {
  // validate minimal schema
  let { error } = Joi.validate(project, schema.minimal);

  if (error) {
    console.error(error);
    return Promise.reject(new errors.VersionNotFoundError('Project file is invalid or does not contain a valid version number'));
  }

  // check version
  if (project.version !== VERSION) {
    console.error('Incompatible version', project.version, VERSION);
    return Promise.reject(new errors.IncompatibleVersionError('Project file is not compatible with this version of the application'));
  }

  // validate full schema
  ({ error } = Joi.validate(project, schema.full));

  if (error) {
    console.error(error);
    return Promise.reject(new errors.InvalidProjectError('Invalid project file'));
  }

  return Promise.resolve(true);
}
