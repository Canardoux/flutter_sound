import type { Components, JSX } from "../dist/types/interface";

interface IonButton extends Components.IonButton, HTMLElement {}
export const IonButton: {
  prototype: IonButton;
  new (): IonButton;
};
