<template>
  <Teleport to="body">
    <div class="overlay" @click.self="$emit('close')">
      <div class="modal">

        <!-- Header -->
        <div class="modal-header">
          <div class="header-meta">
            <span class="type-badge" :class="post.type">{{ post.type || 'video' }}</span>
            <h2 class="modal-title">{{ post.title }}</h2>
            <p v-if="post.subtitle" class="modal-subtitle">{{ post.subtitle }}</p>
          </div>
          <button class="close-btn" @click="$emit('close')" aria-label="Close">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
          </button>
        </div>

        <!-- Media area -->
        <div class="media-area">

          <!-- VIDEO -->
          <template v-if="resolvedType === 'video'">
            <video
              ref="videoEl"
              class="video-player"
              controls
              controlsList="nodownload"
              :poster="post.thumbnail"
              :src="post.file_url"
              @error="mediaError = true"
            ></video>
            <div v-if="mediaError" class="media-error">
              Could not load video. The URL may be restricted or expired.
            </div>
          </template>

          <!-- AUDIO -->
          <template v-else-if="resolvedType === 'audio'">
            <div class="audio-card">
              <div
                class="audio-backdrop"
                :style="post.thumbnail ? `background-image: url(${post.thumbnail})` : ''"
              ></div>
              <div class="audio-inner">
                <div class="audio-art">
                  <img v-if="post.thumbnail" :src="post.thumbnail" alt="" />
                  <div v-else class="audio-art-placeholder">
                    <svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 3v10.55A4 4 0 1 0 14 17V7h4V3z"/></svg>
                  </div>
                </div>
                <audio
                  ref="audioEl"
                  class="audio-native"
                  controls
                  controlsList="nodownload"
                  :src="post.file_url"
                  @error="mediaError = true"
                ></audio>
                <div v-if="mediaError" class="media-error">
                  Could not load audio.
                </div>
              </div>
            </div>
          </template>

          <!-- PDF -->
          <template v-else-if="resolvedType === 'pdf'">
            <div class="pdf-wrap">
              <iframe
                class="pdf-frame"
                :src="pdfSrc"
              ></iframe>
              <a
                :href="post.file_url"
                target="_blank"
                rel="noopener noreferrer"
                class="pdf-open-btn"
              >
                Open PDF directly ↗
              </a>
            </div>
          </template>

          <!-- Unknown type -->
          <template v-else>
            <div class="media-error">Unknown content type: {{ post.type }}</div>
          </template>
        </div>

        <!-- Description -->
        <div v-if="post.description" class="modal-description">
          <p>{{ post.description }}</p>
        </div>

        <!-- Tags row -->
        <div class="modal-tags">
          <span v-if="post.featured" class="tag featured">Featured</span>
          <span v-if="post.hot" class="tag hot">Hot</span>
          <span v-if="post.category_id" class="tag cat">Category: {{ post.category_id }}</span>
        </div>

      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { computed, ref } from 'vue'

const props = defineProps({
  post: { type: Object, required: true },
})
defineEmits(['close'])

const videoEl = ref(null)
const audioEl = ref(null)
const mediaError = ref(false)

const resolvedType = computed(() => (props.post.type || 'video').toLowerCase())

const pdfSrc = computed(() => {
  const url = props.post.file_url
  if (!url) return ''
  return `https://docs.google.com/viewer?url=${encodeURIComponent(url)}&embedded=true`
})
</script>

<style scoped>
/* Overlay */
.overlay {
  position: fixed;
  inset: 0;
  background: rgba(10, 12, 24, 0.72);
  backdrop-filter: blur(4px);
  z-index: 1000;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
  animation: fade-in 0.15s ease;
}

@keyframes fade-in { from { opacity: 0 } to { opacity: 1 } }

/* Modal box */
.modal {
  background: #fff;
  border-radius: 16px;
  width: 100%;
  max-width: 820px;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 24px 60px rgba(0,0,0,0.35);
  animation: slide-up 0.2s ease;
  display: flex;
  flex-direction: column;
}

@keyframes slide-up { from { transform: translateY(20px); opacity: 0 } to { transform: translateY(0); opacity: 1 } }

/* Header */
.modal-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  padding: 20px 24px 16px;
  border-bottom: 1px solid #f0f2f8;
}

.header-meta { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 4px; }

.modal-title {
  margin: 0;
  font-size: 18px;
  font-weight: 700;
  color: #1a1d2e;
  line-height: 1.3;
}

.modal-subtitle {
  margin: 0;
  color: #8b8fa8;
  font-size: 13px;
}

.close-btn {
  flex-shrink: 0;
  width: 34px;
  height: 34px;
  border-radius: 8px;
  border: 1px solid #e8eaf0;
  background: #f8f9fc;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #555;
  transition: all 0.15s;
}
.close-btn:hover { background: #fee2e2; border-color: #fca5a5; color: #c81e1e; }
.close-btn svg { width: 16px; height: 16px; }

/* Type badge */
.type-badge {
  display: inline-block;
  padding: 2px 9px;
  border-radius: 20px;
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  width: fit-content;
}
.type-badge.video { background: #e8f0fe; color: #1a56db; }
.type-badge.audio { background: #f3e8ff; color: #7c3aed; }
.type-badge.pdf   { background: #fde8e8; color: #c81e1e; }

/* Media area */
.media-area {
  background: #0d0e18;
  flex: 1;
}

/* Video */
.video-player {
  width: 100%;
  max-height: 460px;
  display: block;
  background: #000;
}

/* Audio */
.audio-card {
  position: relative;
  min-height: 280px;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.audio-backdrop {
  position: absolute;
  inset: 0;
  background-size: cover;
  background-position: center;
  filter: blur(20px) brightness(0.35);
  transform: scale(1.1);
}

.audio-inner {
  position: relative;
  z-index: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 20px;
  padding: 32px 24px;
  width: 100%;
}

.audio-art {
  width: 120px;
  height: 120px;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 8px 32px rgba(0,0,0,0.5);
  flex-shrink: 0;
}

.audio-art img { width: 100%; height: 100%; object-fit: cover; display: block; }

.audio-art-placeholder {
  width: 100%;
  height: 100%;
  background: #2a2d40;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #7c3aed;
}
.audio-art-placeholder svg { width: 56px; height: 56px; }

.audio-native {
  width: 100%;
  max-width: 480px;
  border-radius: 40px;
  outline: none;
}

/* PDF */
.pdf-wrap {
  display: flex;
  flex-direction: column;
  height: 520px;
}

.pdf-frame {
  flex: 1;
  width: 100%;
  border: none;
  display: block;
}

.pdf-open-btn {
  display: block;
  text-align: center;
  padding: 10px;
  background: #1a1d2e;
  color: #a5b4fc;
  font-size: 13px;
  font-weight: 600;
  text-decoration: none;
  letter-spacing: 0.3px;
  transition: background 0.15s;
}
.pdf-open-btn:hover { background: #2a2d40; }

/* Description */
.modal-description {
  padding: 18px 24px;
  border-top: 1px solid #f0f2f8;
  color: #4b5563;
  font-size: 14px;
  line-height: 1.65;
}

/* Tags */
.modal-tags {
  display: flex;
  gap: 8px;
  padding: 14px 24px;
  border-top: 1px solid #f0f2f8;
  flex-wrap: wrap;
}

.tag {
  font-size: 11px;
  font-weight: 600;
  padding: 3px 10px;
  border-radius: 20px;
  letter-spacing: 0.4px;
}
.tag.featured { background: #fef9c3; color: #a16207; }
.tag.hot      { background: #fee2e2; color: #b91c1c; }
.tag.cat      { background: #f0f9ff; color: #0369a1; }

/* Error */
.media-error {
  padding: 32px;
  text-align: center;
  color: #9ca3af;
  font-size: 13px;
}
</style>
