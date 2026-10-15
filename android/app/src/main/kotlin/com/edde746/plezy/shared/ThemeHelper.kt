package com.edde746.plezy.shared

import android.graphics.Color

object ThemeHelper {
  fun themeColor(mode: String?): Int? = when (mode) {
    "oled" -> Color.BLACK
    "liquid_glass" -> Color.parseColor("#08090C")
    "dark" -> Color.parseColor("#0E0F12")
    "light" -> Color.parseColor("#F7F7F8")
    else -> null
  }
}
