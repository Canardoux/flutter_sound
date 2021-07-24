import type { Components, JSX } from "../dist/types/interface";

interface IonTabBar extends Components.IonTabBar, HTMLElement {}
export const IonTabBar: {
  prototype: IonTabBar;
  new (): IonTabBar;
};
