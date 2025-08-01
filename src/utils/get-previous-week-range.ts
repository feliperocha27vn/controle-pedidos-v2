import { endOfWeek, startOfWeek, subWeeks } from 'date-fns'

export function getPreviousWeekRange() {
  const today = new Date()
  const lastWeek = subWeeks(today, 1)
  const start = startOfWeek(lastWeek)
  const end = endOfWeek(lastWeek)

  return { start, end }
}
