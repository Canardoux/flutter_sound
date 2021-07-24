import type { Components, JSX } from "../dist/types/interface";

interface IonNav extends Components.IonNav, HTMLElement {}
export const IonNav: {
  prototype: IonNav;
  new (): IonNav;
};
