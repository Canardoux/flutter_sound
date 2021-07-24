import type { Components, JSX } from "../dist/types/interface";

interface IonItemOptions extends Components.IonItemOptions, HTMLElement {}
export const IonItemOptions: {
  prototype: IonItemOptions;
  new (): IonItemOptions;
};
