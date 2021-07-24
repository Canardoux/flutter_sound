import type { Components, JSX } from "../dist/types/interface";

interface IonMenu extends Components.IonMenu, HTMLElement {}
export const IonMenu: {
  prototype: IonMenu;
  new (): IonMenu;
};
