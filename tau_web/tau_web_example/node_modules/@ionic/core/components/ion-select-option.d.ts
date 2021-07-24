import type { Components, JSX } from "../dist/types/interface";

interface IonSelectOption extends Components.IonSelectOption, HTMLElement {}
export const IonSelectOption: {
  prototype: IonSelectOption;
  new (): IonSelectOption;
};
