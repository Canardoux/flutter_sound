import type { Components, JSX } from "../dist/types/interface";

interface IonSegment extends Components.IonSegment, HTMLElement {}
export const IonSegment: {
  prototype: IonSegment;
  new (): IonSegment;
};
