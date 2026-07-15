import { fileIo } from '@kit.CoreFileKit';
import { PhotoFileSystem } from './PhotoModels';

interface RuntimeErrorLike {
  message?: string;
  code?: string | number;
}

type RuntimeThrowable = Error | string | RuntimeErrorLike;

export class HarmonyPhotoFileSystem implements PhotoFileSystem {
  async ensureDirectory(path: string): Promise<void> {
    try {
      await fileIo.mkdir(path, true);
    } catch (error) {
      throw new Error(`Failed to create photo directory "${path}": ${runtimeErrorText(error as RuntimeThrowable)}`);
    }
  }

  async copyFile(sourceUri: string, destinationUri: string): Promise<void> {
    try {
      await fileIo.copyFile(sourceUri, destinationUri);
      return;
    } catch (copyError) {
      let sourceFile: fileIo.File | undefined;
      let fallbackFailure: Error | undefined;
      try {
        sourceFile = await fileIo.open(sourceUri, fileIo.OpenMode.READ_ONLY);
        await fileIo.copyFile(sourceFile.fd, destinationUri);
      } catch (fallbackError) {
        fallbackFailure = new Error(
          `Failed to copy photo "${sourceUri}" to "${destinationUri}": ${runtimeErrorText(fallbackError as RuntimeThrowable)}; direct copy: ${runtimeErrorText(copyError as RuntimeThrowable)}`
        );
      } finally {
        if (sourceFile !== undefined) {
          const closeError = await this.closeFile(sourceFile);
          if (fallbackFailure !== undefined && closeError !== undefined) {
            fallbackFailure.message = `${fallbackFailure.message}; close: ${closeError}`;
          }
        }
      }

      if (fallbackFailure !== undefined) {
        throw fallbackFailure;
      }
    }
  }

  async deleteFile(localUri: string): Promise<void> {
    try {
      await fileIo.unlink(localUri);
    } catch (error) {
      throw new Error(`Failed to delete photo "${localUri}": ${runtimeErrorText(error as RuntimeThrowable)}`);
    }
  }

  private async closeFile(file: fileIo.File): Promise<string | undefined> {
    try {
      await fileIo.close(file);
      return undefined;
    } catch (error) {
      return runtimeErrorText(error as RuntimeThrowable);
    }
  }
}

function runtimeErrorText(error: RuntimeThrowable): string {
  if (error instanceof Error && error.message.length > 0) {
    return error.message;
  }

  if (typeof error === 'string' && error.length > 0) {
    return error;
  }

  return runtimeErrorLikeText(error as RuntimeErrorLike);
}

function runtimeErrorLikeText(error: RuntimeErrorLike): string {
  const message = error.message;
  if (message !== undefined && message.length > 0) {
    return message;
  }

  const code = error.code;
  return code !== undefined ? String(code) : 'unavailable error detail';
}
