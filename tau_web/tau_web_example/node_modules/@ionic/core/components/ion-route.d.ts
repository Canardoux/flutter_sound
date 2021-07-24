import type { Components, JSX } from "../dist/types/interface";

interface IonRoute extends Components.IonRoute, HTMLElement {}
export const IonRoute: {
  prototype: IonRoute;
  new (): IonRoute;
};
