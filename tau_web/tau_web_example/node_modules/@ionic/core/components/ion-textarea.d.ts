import type { Components, JSX } from "../dist/types/interface";

interface IonTextarea extends Components.IonTextarea, HTMLElement {}
export const IonTextarea: {
  prototype: IonTextarea;
  new (): IonTextarea;
};
