import type { Components, JSX } from "../dist/types/interface";

interface IonRouter extends Components.IonRouter, HTMLElement {}
export const IonRouter: {
  prototype: IonRouter;
  new (): IonRouter;
};
