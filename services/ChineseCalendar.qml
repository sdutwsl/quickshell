pragma Singleton

import Quickshell
import QtQuick 6.10

Singleton {
    id: root

    // Gregorian -> Chinese lunar calendar data, 1900-2100.
    // Each entry encodes lunar month lengths, leap month and leap-month length.
    readonly property var lunarInfo: [
        0x04bd8,0x04ae0,0x0a570,0x054d5,0x0d260,0x0d950,0x16554,0x056a0,0x09ad0,0x055d2,
        0x04ae0,0x0a5b6,0x0a4d0,0x0d250,0x1d255,0x0b540,0x0d6a0,0x0ada2,0x095b0,0x14977,
        0x04970,0x0a4b0,0x0b4b5,0x06a50,0x06d40,0x1ab54,0x02b60,0x09570,0x052f2,0x04970,
        0x06566,0x0d4a0,0x0ea50,0x06e95,0x05ad0,0x02b60,0x186e3,0x092e0,0x1c8d7,0x0c950,
        0x0d4a0,0x1d8a6,0x0b550,0x056a0,0x1a5b4,0x025d0,0x092d0,0x0d2b2,0x0a950,0x0b557,
        0x06ca0,0x0b550,0x15355,0x04da0,0x0a5d0,0x14573,0x052d0,0x0a9a8,0x0e950,0x06aa0,
        0x0aea6,0x0ab50,0x04b60,0x0aae4,0x0a570,0x05260,0x0f263,0x0d950,0x05b57,0x056a0,
        0x096d0,0x04dd5,0x04ad0,0x0a4d0,0x0d4d4,0x0d250,0x0d558,0x0b540,0x0b5a0,0x195a6,
        0x095b0,0x049b0,0x0a974,0x0a4b0,0x0b27a,0x06a50,0x06d40,0x0af46,0x0ab60,0x09570,
        0x04af5,0x04970,0x064b0,0x074a3,0x0ea50,0x06b58,0x05ac0,0x0ab60,0x096d5,0x092e0,
        0x0c960,0x0d954,0x0d4a0,0x0da50,0x07552,0x056a0,0x0abb7,0x025d0,0x092d0,0x0cab5,
        0x0a950,0x0b4a0,0x0baa4,0x0ad50,0x055d9,0x04ba0,0x0a5b0,0x15176,0x052b0,0x0a930,
        0x07954,0x06aa0,0x0ad50,0x05b52,0x04b60,0x0a6e6,0x0a4e0,0x0d260,0x0ea65,0x0d530,
        0x05aa0,0x076a3,0x096d0,0x04bd7,0x04ad0,0x0a4d0,0x1d0b6,0x0d250,0x0d520,0x0dd45,
        0x0b5a0,0x056d0,0x055b2,0x049b0,0x0a577,0x0a4b0,0x0aa50,0x1b255,0x06d20,0x0ada0,
        0x14b63,0x09370,0x049f8,0x04970,0x064b0,0x168a6,0x0ea50,0x06b20,0x1a6c4,0x0aae0,
        0x0a2e0,0x0d2e3,0x0c960,0x0d557,0x0d4a0,0x0da50,0x05d55,0x056a0,0x0a6d0,0x055d4,
        0x052d0,0x0a9b8,0x0a950,0x0b4a0,0x0b6a6,0x0ad50,0x055a0,0x0aba4,0x0a5b0,0x052b0,
        0x0b273,0x06930,0x07337,0x06aa0,0x0ad50,0x14b55,0x04b60,0x0a570,0x054e4,0x0d160,
        0x0e968,0x0d520,0x0daa0,0x16aa6,0x056d0,0x04ae0,0x0a9d4,0x0a2d0,0x0d150,0x0f252,
        0x0d520
    ]

    readonly property var solarTermMinutes: [
        0,21208,42467,63836,85337,107014,128867,150921,173149,195551,218072,240693,
        263343,285989,308563,331033,353350,375494,397447,419210,440795,462224,483532,504758
    ]

    readonly property var solarTermNames: [
        "小寒","大寒","立春","雨水","惊蛰","春分","清明","谷雨",
        "立夏","小满","芒种","夏至","小暑","大暑","立秋","处暑",
        "白露","秋分","寒露","霜降","立冬","小雪","大雪","冬至"
    ]

    readonly property var lunarMonthNames: [
        "正","二","三","四","五","六","七","八","九","十","冬","腊"
    ]

    // Official State Council holiday schedules. These are intentionally year-specific:
    // compensatory workdays cannot be derived from the lunar calendar.
    readonly property var officialHolidaySchedules: ({
        "2025": {
            ranges: [
                { start: 20250101, end: 20250101, name: "元旦" },
                { start: 20250128, end: 20250204, name: "春节" },
                { start: 20250404, end: 20250406, name: "清明节" },
                { start: 20250501, end: 20250505, name: "劳动节" },
                { start: 20250531, end: 20250602, name: "端午节" },
                { start: 20251001, end: 20251008, name: "国庆/中秋" }
            ],
            workdays: ({
                "20250126": "春节调休",
                "20250208": "春节调休",
                "20250427": "劳动节调休",
                "20250928": "国庆调休",
                "20251011": "国庆调休"
            })
        },
        "2026": {
            ranges: [
                { start: 20260101, end: 20260103, name: "元旦" },
                { start: 20260215, end: 20260223, name: "春节" },
                { start: 20260404, end: 20260406, name: "清明节" },
                { start: 20260501, end: 20260505, name: "劳动节" },
                { start: 20260619, end: 20260621, name: "端午节" },
                { start: 20260925, end: 20260927, name: "中秋节" },
                { start: 20261001, end: 20261007, name: "国庆节" }
            ],
            workdays: ({
                "20260104": "元旦调休",
                "20260214": "春节调休",
                "20260228": "春节调休",
                "20260509": "劳动节调休",
                "20260920": "国庆调休",
                "20261010": "国庆调休"
            })
        }
    })

    function leapMonth(year) {
        if (year < 1900 || year > 2100)
            return 0
        return lunarInfo[year - 1900] & 0xf
    }

    function leapDays(year) {
        const month = leapMonth(year)
        if (!month)
            return 0
        return (lunarInfo[year - 1900] & 0x10000) ? 30 : 29
    }

    function lunarMonthDays(year, month) {
        if (year < 1900 || year > 2100 || month < 1 || month > 12)
            return 0
        return (lunarInfo[year - 1900] & (0x10000 >> month)) ? 30 : 29
    }

    function lunarYearDays(year) {
        if (year < 1900 || year > 2100)
            return 0

        let days = 348
        const info = lunarInfo[year - 1900]
        for (let mask = 0x8000; mask > 0x8; mask >>= 1) {
            if (info & mask)
                days += 1
        }
        return days + leapDays(year)
    }

    function solarToLunar(year, month, day) {
        if (year < 1900 || year > 2100)
            return null

        const base = Date.UTC(1900, 0, 31)
        const target = Date.UTC(year, month - 1, day)
        let offset = Math.floor((target - base) / 86400000)
        if (offset < 0)
            return null

        let lunarYear = 1900
        while (lunarYear <= 2100) {
            const days = lunarYearDays(lunarYear)
            if (offset < days)
                break
            offset -= days
            lunarYear += 1
        }

        if (lunarYear > 2100)
            return null

        const leap = leapMonth(lunarYear)
        let lunarMonth = 1
        let isLeap = false

        while (lunarMonth <= 12) {
            const days = isLeap ? leapDays(lunarYear) : lunarMonthDays(lunarYear, lunarMonth)
            if (offset < days)
                break

            offset -= days
            if (leap && lunarMonth === leap && !isLeap) {
                isLeap = true
            } else {
                if (isLeap)
                    isLeap = false
                lunarMonth += 1
            }
        }

        return {
            year: lunarYear,
            month: lunarMonth,
            day: offset + 1,
            isLeap: isLeap
        }
    }

    function lunarDayName(day) {
        const digits = ["日","一","二","三","四","五","六","七","八","九","十"]
        if (day === 10)
            return "初十"
        if (day === 20)
            return "二十"
        if (day === 30)
            return "三十"

        const prefixes = ["初","十","廿","卅"]
        return prefixes[Math.floor(day / 10)] + digits[day % 10]
    }

    function lunarMonthName(month, isLeap) {
        if (month < 1 || month > 12)
            return ""
        return `${isLeap ? "闰" : ""}${lunarMonthNames[month - 1]}月`
    }

    function lunarShortText(lunar) {
        if (!lunar)
            return ""
        if (lunar.day === 1)
            return lunarMonthName(lunar.month, lunar.isLeap)
        return lunarDayName(lunar.day)
    }

    function lunarFullText(lunar) {
        if (!lunar)
            return ""
        return `${lunarMonthName(lunar.month, lunar.isLeap)}${lunarDayName(lunar.day)}`
    }

    function lunarFestival(lunar) {
        if (!lunar || lunar.isLeap)
            return ""

        const key = `${lunar.month}-${lunar.day}`
        const festivals = ({
            "1-1": "春节",
            "1-15": "元宵",
            "5-5": "端午",
            "7-7": "七夕",
            "8-15": "中秋",
            "9-9": "重阳",
            "12-8": "腊八"
        })

        if (festivals[key])
            return festivals[key]

        if (lunar.month === 12 && lunar.day === lunarMonthDays(lunar.year, 12))
            return "除夕"

        return ""
    }

    function solarFestival(month, day) {
        const festivals = ({
            "1-1": "元旦",
            "5-1": "劳动节",
            "10-1": "国庆节"
        })
        return festivals[`${month}-${day}`] ?? ""
    }

    function solarTermDay(year, index) {
        if (year < 1900 || year > 2100 || index < 0 || index >= 24)
            return -1

        const base = Date.UTC(1900, 0, 6, 2, 5)
        const millis = base
            + 31556925974.7 * (year - 1900)
            + solarTermMinutes[index] * 60000
        return new Date(millis).getUTCDate()
    }

    function solarTerm(year, month, day) {
        if (month < 1 || month > 12)
            return ""

        const firstIndex = (month - 1) * 2
        if (day === solarTermDay(year, firstIndex))
            return solarTermNames[firstIndex]
        if (day === solarTermDay(year, firstIndex + 1))
            return solarTermNames[firstIndex + 1]
        return ""
    }

    function dateNumber(year, month, day) {
        return year * 10000 + month * 100 + day
    }

    function officialHoliday(year, month, day) {
        const schedule = officialHolidaySchedules[`${year}`]
        if (!schedule)
            return null

        const number = dateNumber(year, month, day)
        const workLabel = schedule.workdays[`${number}`]
        if (workLabel)
            return { type: "work", name: workLabel, badge: "班", isStart: false }

        for (let i = 0; i < schedule.ranges.length; i++) {
            const range = schedule.ranges[i]
            if (number >= range.start && number <= range.end) {
                return {
                    type: "rest",
                    name: range.name,
                    badge: "休",
                    isStart: number === range.start
                }
            }
        }

        return null
    }

    function hasOfficialHolidaySchedule(year) {
        return officialHolidaySchedules[`${year}`] !== undefined
    }

    function dateInfo(year, month, day) {
        const lunar = solarToLunar(year, month, day)
        const term = solarTerm(year, month, day)
        const lunarFest = lunarFestival(lunar)
        const solarFest = solarFestival(month, day)
        const holiday = officialHoliday(year, month, day)
        const lunarText = lunarShortText(lunar)

        let label = lunarText
        let special = false

        if (holiday?.isStart) {
            label = holiday.name
            special = true
        }
        if (solarFest) {
            label = solarFest
            special = true
        }
        if (lunarFest) {
            label = lunarFest
            special = true
        }
        if (term) {
            label = term
            special = true
        }

        return {
            lunar: lunar,
            lunarText: lunarText,
            lunarFullText: lunarFullText(lunar),
            solarTerm: term,
            festival: lunarFest || solarFest,
            holiday: holiday,
            label: label,
            special: special,
            supported: lunar !== null
        }
    }
}
