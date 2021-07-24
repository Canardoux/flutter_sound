import type { Components, JSX } from "../dist/types/interface";

interface IonCard extends Components.IonCard, HTMLElement {}
export const IonCard: {
  prototype: IonCard;
  new (): IonCard;
};
