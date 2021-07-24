import type { Components, JSX } from "../dist/types/interface";

interface IonItem extends Components.IonItem, HTMLElement {}
export const IonItem: {
  prototype: IonItem;
  new (): IonItem;
};
