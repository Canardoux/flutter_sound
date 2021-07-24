import type { Components, JSX } from "../dist/types/interface";

interface IonContent extends Components.IonContent, HTMLElement {}
export const IonContent: {
  prototype: IonContent;
  new (): IonContent;
};
