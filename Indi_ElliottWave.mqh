//+------------------------------------------------------------------+
//|                                      Copyright 2016-2021, EA31337 Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
 * This file is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

// Structs.

// Defines struct to store indicator parameter values.
struct Indi_ElliottWave_Params : public IndicatorParams {
  // Indicator params.
  ENUM_APPLIED_PRICE ewo_ap1, ewo_ap2;
  ENUM_MA_METHOD ewo_mm1, ewo_mm2;
  int ewo_period1, ewo_period2;
  // Struct constructors.
  Indi_ElliottWave_Params(int _ewo_period1 = 5, int _ewo_period2 = 35, ENUM_MA_METHOD _ewo_mm1 = MODE_SMA,
                          ENUM_MA_METHOD _ewo_mm2 = MODE_SMA, ENUM_APPLIED_PRICE _ewo_ap1 = PRICE_MEDIAN,
                          ENUM_APPLIED_PRICE _ewo_ap2 = PRICE_MEDIAN, int _shift = 0)
      : ewo_period1(_ewo_period1),
        ewo_period2(_ewo_period2),
        ewo_mm1(_ewo_mm1),
        ewo_mm2(_ewo_mm2),
        ewo_ap1(_ewo_ap1),
        ewo_ap2(_ewo_ap2),
        IndicatorParams(INDI_CUSTOM, 2, TYPE_DOUBLE) {
#ifdef __resource__
    custom_indi_name = "::Indicators\\Elliott_Wave_Oscillator2";
#else
    custom_indi_name = "Elliott_Wave_Oscillator2";
#endif
    shift = _shift;
    SetDataSourceType(IDATA_ICUSTOM);
  };
  Indi_ElliottWave_Params(Indi_ElliottWave_Params &_params, ENUM_TIMEFRAMES _tf) {
    THIS_REF = _params;
    tf = _tf;
  };
  // Getters.
  int GetAppliedPrice1() { return ewo_ap1; }
  int GetAppliedPrice2() { return ewo_ap2; }
  int GetMAMethod1() { return ewo_mm1; }
  int GetMAMethod2() { return ewo_mm2; }
  int GetPeriod1() { return ewo_period1; }
  int GetPeriod2() { return ewo_period2; }
  // Setters.
  void SetAppliedPrice1(ENUM_APPLIED_PRICE _value) { ewo_ap1 = _value; }
  void SetAppliedPrice2(ENUM_APPLIED_PRICE _value) { ewo_ap2 = _value; }
  void SetMAMethod1(ENUM_MA_METHOD _value) { ewo_mm1 = _value; }
  void SetMAMethod2(ENUM_MA_METHOD _value) { ewo_mm2 = _value; }
  void SetPeriod1(int _value) { ewo_period1 = _value; }
  void SetPeriod2(int _value) { ewo_period2 = _value; }
};

/**
 * Implements indicator class.
 */
class Indi_ElliottWave : public Indicator<Indi_ElliottWave_Params> {
 public:
  /**
   * Class constructor.
   */
  Indi_ElliottWave(Indi_ElliottWave_Params &_p, IndicatorBase *_indi_src = NULL)
      : Indicator<Indi_ElliottWave_Params>(_p, _indi_src){};
  Indi_ElliottWave(ENUM_TIMEFRAMES _tf = PERIOD_CURRENT) : Indicator(INDI_ASI, _tf){};

  /**
   * Gets indicator's params.
   */
  // Indi_ElliottWave_Params GetIndiParams() const { return params; }

  /**
   * Returns the indicator's value.
   *
   */
  double GetValue(int _mode, int _shift = 0) {
    ResetLastError();
    double _value = EMPTY_VALUE;
    switch (iparams.idstype) {
      case IDATA_ICUSTOM:
        _value = iCustom(istate.handle, Get<string>(CHART_PARAM_SYMBOL), Get<ENUM_TIMEFRAMES>(CHART_PARAM_TF),
                         iparams.custom_indi_name, iparams.GetPeriod1(), iparams.GetPeriod2(), iparams.GetMAMethod1(),
                         iparams.GetMAMethod2(), iparams.GetAppliedPrice1(), iparams.GetAppliedPrice2(),
                         iparams.GetShift(), _mode, _shift);
        break;
      default:
        SetUserError(ERR_USER_NOT_SUPPORTED);
        _value = EMPTY_VALUE;
    }
    istate.is_changed = false;
    istate.is_ready = _LastError == ERR_NO_ERROR;
    return _value;
  }
};
