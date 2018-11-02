export class InvalidProjectError extends Error {
  constructor(message) {
    super(message);
    this.name = 'InvalidProjectError';
  }
}

export class VersionNotFoundError extends Error {
  constructor(message) {
    super(message);
    this.name = 'VersionNotFoundError';
  }
}

export class IncompatibleVersionError extends Error {
  constructor(message) {
    super(message);
    this.name = 'IncompatibleVersionError';
  }
}
