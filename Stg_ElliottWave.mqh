/**
 * @file
 * Implements ElliottWave strategy. Based on the Elliott Wave indicator.
 *
 * @docs
 * - https://en.wikipedia.org/wiki/Elliott_wave_principle
 */

// User inputs.
INPUT float ElliottWave_LotSize = 0;                 // Lot size
INPUT int ElliottWave_SignalOpenMethod = 0;          // Signal open method (0-1)
INPUT float ElliottWave_SignalOpenLevel = 0.0004f;   // Signal open level (>0.0001)
INPUT int ElliottWave_SignalOpenFilterMethod = 0;    // Signal open filter method
INPUT int ElliottWave_SignalOpenBoostMethod = 0;     // Signal open boost method
INPUT int ElliottWave_SignalCloseMethod = 0;         // Signal close method
INPUT float ElliottWave_SignalCloseLevel = 0.0004f;  // Signal close level (>0.0001)
INPUT int ElliottWave_PriceStopMethod = 0;           // Price stop method
INPUT float ElliottWave_PriceStopLevel = 0;          // Price stop level
INPUT int ElliottWave_TickFilterMethod = 0;          // Tick filter method
INPUT float ElliottWave_MaxSpread = 6.0;             // Max spread to trade (pips)
INPUT int ElliottWave_Shift = 0;                     // Shift (relative to the current bar, 0 - default)
INPUT int ElliottWave_OrderCloseTime = -10;          // Order close time in mins (>0) or bars (<0)

// Includes.
#include <EA31337-classes/Strategy.mqh>

#include "Indi_ElliottWave.mqh"

// Structs.

// Defines struct with default user strategy values.
struct Stg_ElliottWave_Params_Defaults : StgParams {
  Stg_ElliottWave_Params_Defaults()
      : StgParams(::ElliottWave_SignalOpenMethod, ::ElliottWave_SignalOpenFilterMethod, ::ElliottWave_SignalOpenLevel,
                  ::ElliottWave_SignalOpenBoostMethod, ::ElliottWave_SignalCloseMethod, ::ElliottWave_SignalCloseLevel,
                  ::ElliottWave_PriceStopMethod, ::ElliottWave_PriceStopLevel, ::ElliottWave_TickFilterMethod,
                  ::ElliottWave_MaxSpread, ::ElliottWave_Shift, ::ElliottWave_OrderCloseTime) {}
} stg_ewo_defaults;

// Struct to define strategy parameters to override.
struct Stg_ElliottWave_Params : StgParams {
  Indi_ElliottWave_Params iparams;
  StgParams sparams;

  // Struct constructors.
  Stg_ElliottWave_Params(Indi_ElliottWave_Params &_iparams, StgParams &_sparams)
      : iparams(indi_ewo_defaults, _iparams.tf), sparams(stg_ewo_defaults) {
    iparams = _iparams;
    sparams = _sparams;
  }
};

// Loads pair specific param values.
#include "config/EURUSD_H1.h"
#include "config/EURUSD_H4.h"
#include "config/EURUSD_H8.h"
#include "config/EURUSD_M1.h"
#include "config/EURUSD_M15.h"
#include "config/EURUSD_M30.h"
#include "config/EURUSD_M5.h"

class Stg_ElliottWave : public Strategy {
 public:
  Stg_ElliottWave(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_ElliottWave *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Indi_ElliottWave_Params _indi_params(indi_ewo_defaults, _tf);
    StgParams _stg_params(stg_ewo_defaults);
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<Indi_ElliottWave_Params>(_indi_params, _tf, indi_ewo_m1, indi_ewo_m5, indi_ewo_m15, indi_ewo_m30,
                                             indi_ewo_h1, indi_ewo_h4, indi_ewo_h8);
      SetParamsByTf<StgParams>(_stg_params, _tf, stg_ewo_m1, stg_ewo_m5, stg_ewo_m15, stg_ewo_m30, stg_ewo_h1,
                               stg_ewo_h4, stg_ewo_h8);
    }
    // Initialize indicator.
    Indi_ElliottWave_Params _ewo_params(_indi_params, _tf);
    _stg_params.SetIndicator(new Indi_ElliottWave(_ewo_params));
    // Initialize strategy parameters.
    _stg_params.GetLog().SetLevel(_log_level);
    _stg_params.SetMagicNo(_magic_no);
    _stg_params.SetTf(_tf, _Symbol);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_ElliottWave(_stg_params, "Elliott Wave");
    _stg_params.SetStops(_strat, _strat);
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indicator *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid();
    bool _result = _is_valid;
    if (!_result) {
      // Returns false when indicator data is not valid.
      return false;
    }
    double pip_level = _level * Chart().GetPipSize();
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result = _indi[CURR].value[0] < _indi[CURR].value[1] + pip_level;
        if (_method != 0) {
          // if (METHOD(_method, 0)) _result &= fmin(Close[PREV], Close[PPREV]) < _indi[CURR].value[TMA_TRUE_LOWER];
        }
        break;
      case ORDER_TYPE_SELL:
        _result = _indi[CURR].value[1] > _indi[CURR].value[0] + pip_level;
        if (_method != 0) {
          // if (METHOD(_method, 0)) _result &= fmin(Close[PREV], Close[PPREV]) > _indi[CURR].value[TMA_TRUE_UPPER];
        }
        break;
    }
    /*
    // @todo

    if ((fasterEMA[0][tframe] > slowerEMA[0][tframe]) && (fasterEMA[1][tframe] < slowerEMA[1][tframe]) &&
        (fasterEMA[2][tframe] > slowerEMA[2][tframe]) && (_cmd == OP_BUY)) {
      return True;
    } else if ((fasterEMA[0][tframe] < slowerEMA[0][tframe]) && (fasterEMA[1][tframe] > slowerEMA[1][tframe]) &&
               (fasterEMA[2][tframe] < slowerEMA[2][tframe]) && (_cmd == OP_SELL)) {
      return True;
    }
    */

    return _result;
  }

  /**
   * Gets price stop value for profit take or stop loss.
   */
  float PriceStop(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Indi_ElliottWave *_indi = Data();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    switch (_method) {
      case 1:
        //_result = (_direction > 0 ? _indi[CURR].value[0] : _indi[CURR].value[1]) + _trail * _direction;
        break;
    }
    return (float)_result;
  }
};
