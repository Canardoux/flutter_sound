import type { Components, JSX } from "../dist/types/interface";

interface IonTab extends Components.IonTab, HTMLElement {}
export const IonTab: {
  prototype: IonTab;
  new (): IonTab;
};
