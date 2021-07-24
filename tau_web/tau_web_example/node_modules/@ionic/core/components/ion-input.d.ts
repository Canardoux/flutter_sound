import type { Components, JSX } from "../dist/types/interface";

interface IonInput extends Components.IonInput, HTMLElement {}
export const IonInput: {
  prototype: IonInput;
  new (): IonInput;
};
