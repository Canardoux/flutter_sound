import type { Components, JSX } from "../dist/types/interface";

interface IonList extends Components.IonList, HTMLElement {}
export const IonList: {
  prototype: IonList;
  new (): IonList;
};
