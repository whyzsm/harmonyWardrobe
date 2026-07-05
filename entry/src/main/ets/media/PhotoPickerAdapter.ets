import { cameraPicker } from '@kit.CameraKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import common from '@ohos.app.ability.common';
import { PhotoSource } from './PhotoModels';

const DEFAULT_MAX_SELECT_NUMBER = 20;
const MAX_GALLERY_SELECT_NUMBER = 20;
const IMAGE_MIME_TYPE = 'image/*';

interface PickerErrorLike {
  message?: string;
  code?: string | number;
}

type PickerThrowable = Error | string | PickerErrorLike;

export interface GalleryPickOptions {
  maxSelectNumber?: number;
}

export interface CameraCaptureOptions {
  fileName?: string;
  mimeType?: string;
  profile?: cameraPicker.PickerProfile;
}

export interface GalleryPickerProvider {
  pickImages(maxSelectNumber: number): Promise<Array<string>>;
}

export interface CameraCaptureProvider {
  capturePhoto(options?: CameraCaptureOptions): Promise<string>;
}

export class HarmonyGalleryPickerProvider implements GalleryPickerProvider {
  async pickImages(maxSelectNumber: number): Promise<Array<string>> {
    const options = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = maxSelectNumber;

    const picker = new photoAccessHelper.PhotoViewPicker();
    try {
      const result = await picker.select(options);
      return result.photoUris;
    } catch (error) {
      throw new Error(`HarmonyOS gallery picker failed: ${errorText(error as PickerThrowable)}`);
    }
  }
}

export class HarmonyCameraCaptureProvider implements CameraCaptureProvider {
  private readonly context: common.Context;

  constructor(context: common.Context) {
    this.context = context;
  }

  async capturePhoto(options?: CameraCaptureOptions): Promise<string> {
    const profile = options?.profile ?? this.createDefaultPickerProfile();
    const result = await cameraPicker.pick(
      this.context,
      [cameraPicker.PickerMediaType.PHOTO],
      profile
    );

    if (result.resultUri.trim().length === 0) {
      throw new Error('HarmonyOS camera did not return a photo URI.');
    }

    return result.resultUri;
  }

  private createDefaultPickerProfile(): cameraPicker.PickerProfile {
    try {
      return new cameraPicker.PickerProfile();
    } catch (error) {
      throw new Error(`HarmonyOS camera picker profile failed: ${errorText(error as PickerThrowable)}`);
    }
  }
}

function errorText(error: PickerThrowable): string {
  if (error instanceof Error && error.message.length > 0) {
    return error.message;
  }

  if (typeof error === 'string' && error.length > 0) {
    return error;
  }

  return pickerErrorLikeText(error as PickerErrorLike);
}

function pickerErrorLikeText(error: PickerErrorLike): string {
  const message = error.message;
  if (message !== undefined && message.length > 0) {
    return message;
  }

  const code = error.code;
  return code !== undefined ? String(code) : 'unavailable error detail';
}

function normalizeMaxSelectNumber(value?: number): number {
  if (value === undefined || !Number.isFinite(value)) {
    return DEFAULT_MAX_SELECT_NUMBER;
  }

  const flooredValue = Math.floor(value);
  return Math.min(MAX_GALLERY_SELECT_NUMBER, Math.max(1, flooredValue));
}

export class PhotoPickerAdapter {
  private readonly galleryProvider: GalleryPickerProvider;
  private readonly cameraProvider?: CameraCaptureProvider;

  constructor(
    galleryProvider?: GalleryPickerProvider,
    cameraProvider?: CameraCaptureProvider
  ) {
    this.galleryProvider = galleryProvider ?? new HarmonyGalleryPickerProvider();
    this.cameraProvider = cameraProvider;
  }

  static withHarmonyProviders(context: common.Context): PhotoPickerAdapter {
    return new PhotoPickerAdapter(
      new HarmonyGalleryPickerProvider(),
      new HarmonyCameraCaptureProvider(context)
    );
  }

  async pickFromGallery(options?: GalleryPickOptions): Promise<PhotoSource[]> {
    const maxSelectNumber = normalizeMaxSelectNumber(options?.maxSelectNumber);
    const uris = await this.galleryProvider.pickImages(maxSelectNumber);

    return uris
      .filter((uri: string): boolean => uri.trim().length > 0)
      .map((uri: string): PhotoSource => ({
        uri,
        mimeType: IMAGE_MIME_TYPE
      }));
  }

  async captureFromCamera(options?: CameraCaptureOptions): Promise<PhotoSource> {
    if (!this.cameraProvider) {
      throw new Error('Camera provider is required to capture a photo.');
    }

    const uri = await this.cameraProvider.capturePhoto(options);

    if (uri.trim().length === 0) {
      throw new Error('HarmonyOS camera did not return a photo URI.');
    }

    return {
      uri,
      fileName: options?.fileName,
      mimeType: options?.mimeType ?? IMAGE_MIME_TYPE
    };
  }
}
