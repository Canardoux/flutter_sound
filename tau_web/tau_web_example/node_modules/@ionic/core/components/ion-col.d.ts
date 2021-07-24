import type { Components, JSX } from "../dist/types/interface";

interface IonCol extends Components.IonCol, HTMLElement {}
export const IonCol: {
  prototype: IonCol;
  new (): IonCol;
};
