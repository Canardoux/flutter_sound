import type { Components, JSX } from "../dist/types/interface";

interface IonNavLink extends Components.IonNavLink, HTMLElement {}
export const IonNavLink: {
  prototype: IonNavLink;
  new (): IonNavLink;
};
