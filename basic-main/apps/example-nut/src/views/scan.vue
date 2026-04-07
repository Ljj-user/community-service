<script setup lang="ts">
import { toast } from 'vue-sonner'

definePage({
  meta: {
    title: '扫一扫',
    auth: true,
  },
})

const router = useRouter()
const videoRef = ref<HTMLVideoElement | null>(null)
const fileInputRef = ref<HTMLInputElement | null>(null)
const cameraError = ref('')
const scanning = ref(false)

let stream: MediaStream | null = null

/** 浏览器 BarcodeDetector（部分 TS lib 未包含类型） */
interface BarcodeDetectorLike {
  detect(image: ImageBitmapSource): Promise<Array<{ rawValue: string }>>
}
interface BarcodeDetectorCtor {
  new (options?: { formats?: string[] }): BarcodeDetectorLike
}

function getBarcodeCtor(): BarcodeDetectorCtor | null {
  if (typeof globalThis === 'undefined')
    return null
  return (globalThis as unknown as { BarcodeDetector?: BarcodeDetectorCtor }).BarcodeDetector ?? null
}

async function startCamera() {
  cameraError.value = ''
  if (!navigator.mediaDevices?.getUserMedia) {
    cameraError.value = '当前环境不支持摄像头'
    return
  }
  try {
    stream = await navigator.mediaDevices.getUserMedia({
      video: { facingMode: { ideal: 'environment' } },
      audio: false,
    })
    const el = videoRef.value
    if (el) {
      el.srcObject = stream
      await el.play()
    }
  }
  catch (e: unknown) {
    cameraError.value = e instanceof Error ? e.message : '无法打开摄像头'
  }
}

onMounted(startCamera)

onBeforeUnmount(() => {
  if (stream) {
    stream.getTracks().forEach(t => t.stop())
    stream = null
  }
})

function openAlbum() {
  fileInputRef.value?.click()
}

async function onFileChange(e: Event) {
  const input = e.target as HTMLInputElement
  const file = input.files?.[0]
  input.value = ''
  if (!file)
    return

  const BarcodeDetectorCtor = getBarcodeCtor()
  if (!BarcodeDetectorCtor) {
    toast.error('当前浏览器不支持二维码识别', {
      description: '请使用 Chrome / Edge 等支持 BarcodeDetector 的浏览器',
    })
    return
  }

  scanning.value = true
  try {
    const bmp = await createImageBitmap(file)
    const canvas = document.createElement('canvas')
    canvas.width = bmp.width
    canvas.height = bmp.height
    const ctx = canvas.getContext('2d')
    if (!ctx) {
      toast.error('无法处理图片')
      return
    }
    ctx.drawImage(bmp, 0, 0)
    bmp.close()

    const detector = new BarcodeDetectorCtor({ formats: ['qr_code'] })
    const codes = await detector.detect(canvas)
    if (!codes.length) {
      toast.error('未识别到二维码')
      return
    }
    const raw = codes[0].rawValue
    handleScanResult(raw)
  }
  catch (err: unknown) {
    toast.error(err instanceof Error ? err.message : '识别失败')
  }
  finally {
    scanning.value = false
  }
}

function handleScanResult(text: string) {
  const t = text.trim()
  toast.success('识别成功', { description: t.length > 96 ? `${t.slice(0, 96)}…` : t })

  if (/^https?:\/\//i.test(t)) {
    try {
      const u = new URL(t)
      const hashPath = u.hash?.replace(/^#/, '') || ''
      if (hashPath.startsWith('/')) {
        router.push(hashPath)
        return
      }
    }
    catch {
      /* 非标准 URL，走外链 */
    }
    window.open(t, '_blank', 'noopener,noreferrer')
  }
}
</script>

<template>
  <AppPageLayout :navbar="false" tabbar>
    <div class="scan-page">
      <header class="top">
        <button type="button" class="back-btn" aria-label="返回" @click="router.back()">
          <FmIcon name="i-carbon:arrow-left" />
        </button>
        <h2>扫一扫</h2>
      </header>

      <p class="hint">
        对准二维码扫描，或从相册选择含码图片（需浏览器支持识别 API）
      </p>

      <div class="viewport">
        <video
          v-show="!cameraError"
          ref="videoRef"
          class="camera"
          playsinline
          muted
        />
        <div v-if="cameraError" class="camera-fallback">
          <FmIcon name="i-carbon:qr-code" class="big-ico" />
          <span>{{ cameraError }}</span>
        </div>

        <div class="scan-frame" aria-hidden="true">
          <span class="c tl" />
          <span class="c tr" />
          <span class="c bl" />
          <span class="c br" />
          <span class="scan-line" />
        </div>

        <div v-if="scanning" class="scan-mask">
          识别中…
        </div>
      </div>

      <NutButton block type="primary" class="album-btn" :disabled="scanning" @click="openAlbum">
        从相册识别
      </NutButton>
      <input
        ref="fileInputRef"
        type="file"
        accept="image/*"
        class="hidden-input"
        @change="onFileChange"
      >
    </div>
  </AppPageLayout>
</template>

<style scoped>
.scan-page { height: 100%; background: #f4f6f8; padding: 10px 12px 20px; display: flex; flex-direction: column; }
.top { display: flex; align-items: center; gap: 10px; padding: 6px 0 4px; flex-shrink: 0; }
.back-btn { border: 0; background: #fff; width: 34px; height: 34px; border-radius: 999px; display: inline-flex; align-items: center; justify-content: center; color: #111827; }
.top h2 { margin: 0; font-size: 18px; font-weight: 900; flex: 1; text-align: center; padding-right: 34px; }
.hint { margin: 0 0 12px; font-size: 12px; color: #6b7280; line-height: 1.45; }

.viewport {
  position: relative;
  width: 100%;
  aspect-ratio: 1;
  max-height: min(64vh, 420px);
  margin: 0 auto 16px;
  border-radius: 16px;
  overflow: hidden;
  background: #0f172a;
  box-shadow: 0 8px 28px rgba(15, 23, 42, .18);
}
.camera { width: 100%; height: 100%; object-fit: cover; display: block; }
.camera-fallback {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 10px;
  color: #94a3b8;
  font-size: 13px;
  text-align: center;
  padding: 16px;
}
.big-ico { font-size: 48px; opacity: .85; }

.scan-frame {
  position: absolute;
  inset: 0;
  pointer-events: none;
}
.scan-frame .c {
  position: absolute;
  width: 28px;
  height: 28px;
  border-color: #34d399;
  border-style: solid;
  border-width: 0;
  opacity: .95;
}
.scan-frame .tl { top: 14%; left: 14%; border-top-width: 3px; border-left-width: 3px; border-top-left-radius: 4px; }
.scan-frame .tr { top: 14%; right: 14%; border-top-width: 3px; border-right-width: 3px; border-top-right-radius: 4px; }
.scan-frame .bl { bottom: 14%; left: 14%; border-bottom-width: 3px; border-left-width: 3px; border-bottom-left-radius: 4px; }
.scan-frame .br { bottom: 14%; right: 14%; border-bottom-width: 3px; border-right-width: 3px; border-bottom-right-radius: 4px; }

.scan-line {
  position: absolute;
  left: 18%;
  right: 18%;
  height: 2px;
  top: 22%;
  background: linear-gradient(90deg, transparent, #6ee7b7, #34d399, #6ee7b7, transparent);
  border-radius: 2px;
  box-shadow: 0 0 12px rgba(52, 211, 153, .7);
  animation: scan-sweep 2.4s ease-in-out infinite;
}

@keyframes scan-sweep {
  0%, 100% { top: 22%; opacity: .6; }
  50% { top: 72%; opacity: 1; }
}

.scan-mask {
  position: absolute;
  inset: 0;
  background: rgba(15, 23, 42, .55);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 15px;
  font-weight: 700;
}

.album-btn { flex-shrink: 0; }
.hidden-input { position: absolute; width: 0; height: 0; opacity: 0; pointer-events: none; }

:global(.dark) .scan-page { background: #111827; }
:global(.dark) .back-btn { background: #1f2937; color: #f3f4f6; border: 1px solid #374151; }
:global(.dark) .top h2 { color: #f3f4f6; }
:global(.dark) .hint { color: #9ca3af; }
</style>
