// Shared by the interaction triggers in this directory (counters.js,
// activityNotifications.js) — detects create-vs-delete on an
// onDocumentWritten event so each trigger only reacts to the transition it
// cares about.
function transitionDelta(event) {
  const existedBefore = event.data.before.exists;
  const existsAfter = event.data.after.exists;
  if (!existedBefore && existsAfter) return 1;
  if (existedBefore && !existsAfter) return -1;
  return 0;
}

module.exports = { transitionDelta };
