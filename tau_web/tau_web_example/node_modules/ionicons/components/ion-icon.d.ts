import type { Components, JSX } from "../dist/types/components";

interface IonIcon extends Components.IonIcon, HTMLElement {}
export const IonIcon: {
  prototype: IonIcon;
  new (): IonIcon;
};
