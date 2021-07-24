var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
import { r as registerInstance, c as createEvent, h } from './core-f86805ad.js';
var PWACameraModal = /** @class */ (function () {
    function class_1(hostRef) {
        registerInstance(this, hostRef);
        this.onPhoto = createEvent(this, "onPhoto", 7);
        this.noDeviceError = createEvent(this, "noDeviceError", 7);
    }
    class_1.prototype.present = function () {
        return __awaiter(this, void 0, void 0, function () {
            var camera;
            var _this = this;
            return __generator(this, function (_a) {
                camera = document.createElement('pwa-camera-modal-instance');
                camera.addEventListener('onPhoto', function (e) { return __awaiter(_this, void 0, void 0, function () {
                    var photo;
                    return __generator(this, function (_a) {
                        if (!this._modal) {
                            return [2 /*return*/];
                        }
                        photo = e.detail;
                        this.onPhoto.emit(photo);
                        return [2 /*return*/];
                    });
                }); });
                camera.addEventListener('noDeviceError', function (e) { return __awaiter(_this, void 0, void 0, function () {
                    return __generator(this, function (_a) {
                        this.noDeviceError.emit(e);
                        return [2 /*return*/];
                    });
                }); });
                document.body.append(camera);
                this._modal = camera;
                return [2 /*return*/];
            });
        });
    };
    class_1.prototype.dismiss = function () {
        return __awaiter(this, void 0, void 0, function () {
            return __generator(this, function (_a) {
                if (!this._modal) {
                    return [2 /*return*/];
                }
                this._modal && this._modal.parentNode.removeChild(this._modal);
                this._modal = null;
                return [2 /*return*/];
            });
        });
    };
    class_1.prototype.render = function () {
        return (h("div", null));
    };
    Object.defineProperty(class_1, "style", {
        get: function () { return ":host{z-index:1000;position:fixed;top:0;left:0;width:100%;height:100%;contain:strict}.wrapper,:host{display:-ms-flexbox;display:flex}.wrapper{-ms-flex:1;flex:1;-ms-flex-align:center;align-items:center;-ms-flex-pack:center;justify-content:center;background-color:rgba(0,0,0,.15)}.content{-webkit-box-shadow:0 0 5px rgba(0,0,0,.2);box-shadow:0 0 5px rgba(0,0,0,.2);width:600px;height:600px}"; },
        enumerable: true,
        configurable: true
    });
    return class_1;
}());
export { PWACameraModal as pwa_camera_modal };
