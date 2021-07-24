import { Animation } from '../../../interface';
export declare const SwipeToCloseDefaults: {
  MIN_PRESENTING_SCALE: number;
};
export declare const createSwipeToCloseGesture: (el: HTMLIonModalElement, animation: Animation, onDismiss: () => void) => import("../../../interface").Gesture;
