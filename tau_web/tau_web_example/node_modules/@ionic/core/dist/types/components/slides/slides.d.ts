import { ComponentInterface, EventEmitter } from '../../stencil-public-runtime';
/**
 * @virtualProp {"ios" | "md"} mode - The mode determines which platform styles to use.
 */
export declare class Slides implements ComponentInterface {
  private scrollbarEl?;
  private paginationEl?;
  private swiperReady;
  private mutationO?;
  private readySwiper;
  private swiper;
  private syncSwiper?;
  private didInit;
  el: HTMLIonSlidesElement;
  /**
   * Options to pass to the swiper instance.
   * See http://idangero.us/swiper/api/ for valid options
   */
  options: any;
  optionsChanged(): Promise<void>;
  /**
   * If `true`, show the pagination.
   */
  pager: boolean;
  /**
   * If `true`, show the scrollbar.
   */
  scrollbar: boolean;
  /**
   * Emitted after Swiper initialization
   */
  ionSlidesDidLoad: EventEmitter<void>;
  /**
   * Emitted when the user taps/clicks on the slide's container.
   */
  ionSlideTap: EventEmitter<void>;
  /**
   * Emitted when the user double taps on the slide's container.
   */
  ionSlideDoubleTap: EventEmitter<void>;
  /**
   * Emitted before the active slide has changed.
   */
  ionSlideWillChange: EventEmitter<void>;
  /**
   * Emitted after the active slide has changed.
   */
  ionSlideDidChange: EventEmitter<void>;
  /**
   * Emitted when the next slide has started.
   */
  ionSlideNextStart: EventEmitter<void>;
  /**
   * Emitted when the previous slide has started.
   */
  ionSlidePrevStart: EventEmitter<void>;
  /**
   * Emitted when the next slide has ended.
   */
  ionSlideNextEnd: EventEmitter<void>;
  /**
   * Emitted when the previous slide has ended.
   */
  ionSlidePrevEnd: EventEmitter<void>;
  /**
   * Emitted when the slide transition has started.
   */
  ionSlideTransitionStart: EventEmitter<void>;
  /**
   * Emitted when the slide transition has ended.
   */
  ionSlideTransitionEnd: EventEmitter<void>;
  /**
   * Emitted when the slider is actively being moved.
   */
  ionSlideDrag: EventEmitter<void>;
  /**
   * Emitted when the slider is at its initial position.
   */
  ionSlideReachStart: EventEmitter<void>;
  /**
   * Emitted when the slider is at the last slide.
   */
  ionSlideReachEnd: EventEmitter<void>;
  /**
   * Emitted when the user first touches the slider.
   */
  ionSlideTouchStart: EventEmitter<void>;
  /**
   * Emitted when the user releases the touch.
   */
  ionSlideTouchEnd: EventEmitter<void>;
  connectedCallback(): void;
  disconnectedCallback(): void;
  /**
   * Update the underlying slider implementation. Call this if you've added or removed
   * child slides.
   */
  update(): Promise<void>;
  /**
   * Force swiper to update its height (when autoHeight is enabled) for the duration
   * equal to 'speed' parameter.
   *
   * @param speed The transition duration (in ms).
   */
  updateAutoHeight(speed?: number): Promise<void>;
  /**
   * Transition to the specified slide.
   *
   * @param index The index of the slide to transition to.
   * @param speed The transition duration (in ms).
   * @param runCallbacks If true, the transition will produce [Transition/SlideChange][Start/End] transition events.
   */
  slideTo(index: number, speed?: number, runCallbacks?: boolean): Promise<void>;
  /**
   * Transition to the next slide.
   *
   * @param speed The transition duration (in ms).
   * @param runCallbacks If true, the transition will produce [Transition/SlideChange][Start/End] transition events.
   */
  slideNext(speed?: number, runCallbacks?: boolean): Promise<void>;
  /**
   * Transition to the previous slide.
   *
   * @param speed The transition duration (in ms).
   * @param runCallbacks If true, the transition will produce the [Transition/SlideChange][Start/End] transition events.
   */
  slidePrev(speed?: number, runCallbacks?: boolean): Promise<void>;
  /**
   * Get the index of the active slide.
   */
  getActiveIndex(): Promise<number>;
  /**
   * Get the index of the previous slide.
   */
  getPreviousIndex(): Promise<number>;
  /**
   * Get the total number of slides.
   */
  length(): Promise<number>;
  /**
   * Get whether or not the current slide is the last slide.
   */
  isEnd(): Promise<boolean>;
  /**
   * Get whether or not the current slide is the first slide.
   */
  isBeginning(): Promise<boolean>;
  /**
   * Start auto play.
   */
  startAutoplay(): Promise<void>;
  /**
   * Stop auto play.
   */
  stopAutoplay(): Promise<void>;
  /**
   * Lock or unlock the ability to slide to the next slide.
   *
   * @param lock If `true`, disable swiping to the next slide.
   */
  lockSwipeToNext(lock: boolean): Promise<void>;
  /**
   * Lock or unlock the ability to slide to the previous slide.
   *
   * @param lock If `true`, disable swiping to the previous slide.
   */
  lockSwipeToPrev(lock: boolean): Promise<void>;
  /**
   * Lock or unlock the ability to slide to the next or previous slide.
   *
   * @param lock If `true`, disable swiping to the next and previous slide.
   */
  lockSwipes(lock: boolean): Promise<void>;
  /**
   * Get the Swiper instance.
   * Use this to access the full Swiper API.
   * See https://idangero.us/swiper/api/ for all API options.
   */
  getSwiper(): Promise<any>;
  private initSwiper;
  private normalizeOptions;
  render(): any;
}
