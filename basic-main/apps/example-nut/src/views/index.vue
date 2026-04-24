<script setup lang="ts">
import { getUserAnnouncementDetail, listUserAnnouncements, type AnnouncementVO } from '@/api/modules/announcements'
import { listBanners, type BannerVO } from '@/api/modules/banner'

definePage({
  meta: {
    title: '大厅',
    auth: true,
  },
})

const appAuthStore = useAppAuthStore()
const router = useRouter()

const loading = ref(false)
const error = ref('')
const communityOptions = ['幸福里社区', '阳光社区', '和谐社区']
/** 仅用于公告区演示数据；顶部社区显示以“后端绑定社区”为准 */
const noticeCommunity = ref(communityOptions[0])
const communityDistanceMap: Record<string, string> = {
  幸福里社区: '0.8km',
  阳光社区: '1.6km',
  和谐社区: '2.4km',
}
const bannerList = ref<Array<{ id: number; title: string; sub: string }>>([])
const bannerFallback = [
  { id: 1, title: '春季互助行动', sub: '邻里协作让生活更轻松' },
  { id: 2, title: '积分激励周', sub: '完成服务可获额外贡献积分' },
  { id: 3, title: '社区关怀日', sub: '优先帮助独居老人和行动不便居民' },
]

const displayName = computed(() => appAuthStore.user?.realName || appAuthStore.user?.username || appAuthStore.account || '邻里用户')
/** 后端 sys_region 名称，未绑定则提示文案 */
const resolvedCommunityName = computed(() => appAuthStore.user?.communityName || '未绑定社区')
/** 省、市 + 社区名（横幅展示：浙江省 杭州市 · 幸福社区） */
const bannerLocationSubtitle = computed(() => {
  const u = appAuthStore.user
  const name = u?.communityName || '未绑定社区'
  const p = u?.province?.trim()
  const c = u?.city?.trim()
  if (p && c) return `${p} ${c} · ${name}`
  if (p) return `${p} · ${name}`
  if (c) return `${c} · ${name}`
  return name
})
const bannerUserName = computed(() => displayName.value || '邻里用户')
const accountAvatarUrl = computed(() => appAuthStore.user?.avatarUrl || '')
/** 与 sys_user.points 一致（信用分/积分） */
const creditScore = computed(() => Number(appAuthStore.user?.points ?? 0))
// 顶部不再模拟“距离”，避免与绑定社区逻辑冲突；展示占位
const headerDistance = computed(() => (appAuthStore.user?.communityName ? '已绑定' : '去绑定'))
/** 需求卡片上展示的距离仍跟公告切换社区（演示）一致 */
const listDistance = computed(() => communityDistanceMap[noticeCommunity.value] ?? '—')
const announcementRows = ref<AnnouncementVO[]>([])

const showAnnouncementModal = ref(false)
const announcementDetailLoading = ref(false)
const announcementDetailError = ref('')
const announcementDetail = ref<AnnouncementVO | null>(null)
/** 点击列表时暂存，用于详情加载前展示标题 */
const announcementListItem = ref<AnnouncementVO | null>(null)
let loadSeq = 0

function fmtAnnounceTime(v?: string) {
  if (!v) return ''
  return v.replace('T', ' ').slice(0, 16)
}

async function loadData() {
  const seq = ++loadSeq
  loading.value = true
  error.value = ''
  try {
    await appAuthStore.hydrateUserThrottled?.()
    const bound = appAuthStore.user?.communityName
    if (bound && communityOptions.includes(bound))
      noticeCommunity.value = bound
    const [bannerRes, annRes] = await Promise.all([
      listBanners(),
      listUserAnnouncements(1, 30),
    ])
    // 若用户快速切换分类/刷新，只应用最后一次请求结果
    if (seq !== loadSeq) return
    if (bannerRes.code === 200 && Array.isArray(bannerRes.data)) {
      const mapped = (bannerRes.data as BannerVO[])
        .filter(x => x && x.title)
        .map(x => ({ id: x.id, title: x.title, sub: x.subtitle || '' }))
      bannerList.value = mapped.length ? mapped : bannerFallback
    }
    else {
      bannerList.value = bannerFallback
    }
    if (annRes.code === 200)
      announcementRows.value = annRes.data.records || []
    else
      announcementRows.value = []
  }
  catch (e: any) {
    if (seq !== loadSeq) return
    error.value = e?.message || '加载失败'
  }
  finally {
    if (seq !== loadSeq) return
    loading.value = false
  }
}

function onGotoMe() {
  router.push('/user/')
}

function onScan() {
  router.push('/scan')
}

function onOpenAiAssistant() {
  router.push('/ai-assistant')
}

function onChangeCommunity() {
  router.push('/join-community')
}

function onViewAllAnnouncements() {
  router.push({ path: '/notices' })
}

function onGotoHelp() {
  router.push('/hall-take')
}

function onGotoPublish() {
  router.push('/hall-publish')
}

function onGotoTasks() {
  router.push('/hall')
}

function onGotoOverview(kind: 'reviews' | 'stats') {
  router.push({ path: '/hall-overview', query: { kind } })
}

async function openAnnouncementDetail(n: AnnouncementVO) {
  announcementListItem.value = n
  showAnnouncementModal.value = true
  announcementDetail.value = null
  announcementDetailError.value = ''
  announcementDetailLoading.value = true
  try {
    const res = await getUserAnnouncementDetail(n.id)
    if (res.code !== 200 || !res.data)
      throw new Error(res.message || '加载失败')
    announcementDetail.value = res.data
  }
  catch (e: any) {
    announcementDetailError.value = e?.message || '加载失败'
  }
  finally {
    announcementDetailLoading.value = false
  }
}

watch(showAnnouncementModal, (open) => {
  if (!open) {
    announcementDetail.value = null
    announcementListItem.value = null
    announcementDetailError.value = ''
    announcementDetailLoading.value = false
  }
})

onMounted(loadData)
</script>

<template>
  <AppPageLayout :navbar="false" tabbar>
    <div class="home-page">
      <header class="biz-header">
        <button class="community-switch" @click="onChangeCommunity">
          <FmIcon name="i-carbon:location-filled" class="community-icon" />
          <span class="community-main">{{ resolvedCommunityName }}</span>
          <span class="community-tip">点击切换社区</span>
          <span class="distance">{{ headerDistance }}</span>
          <FmIcon name="i-carbon:chevron-right" />
        </button>
        <button type="button" class="scan-btn" aria-label="扫一扫" @click="onScan">
          <span class="scan-glyph" aria-hidden="true" />
        </button>
        <button type="button" class="ai-btn" aria-label="AI助手" @click="onOpenAiAssistant">
          AI
        </button>
      </header>

      <main class="content-scroll">
        <NutSwiper :auto-play="3000" :pagination-visible="true" class="hero-swiper">
          <NutSwiperItem v-for="b in bannerList" :key="b.id">
            <div class="hero-item">
              <div class="hero-title">
                {{ b.title }}
              </div>
              <div v-if="b.sub" class="hero-sub">
                {{ b.sub }}
              </div>
              <div class="hero-user">
                你好，{{ bannerUserName }} · {{ bannerLocationSubtitle }}
              </div>
            </div>
          </NutSwiperItem>
        </NutSwiper>

        <button class="account-card" @click="onGotoMe">
          <div class="avatar-wrap">
            <img v-if="accountAvatarUrl" :src="accountAvatarUrl" alt="avatar">
            <FmIcon v-else name="i-carbon:user-avatar-filled-alt" />
          </div>
          <div class="account-left">
            <div class="mini-label">
              我的账户
            </div>
            <div class="account-name">
              {{ displayName }}
            </div>
            <div class="account-sub">
              {{ resolvedCommunityName }}
            </div>
          </div>
          <div class="account-right">
            <div class="mini-label">
              贡献积分
            </div>
            <div class="account-coins">
              {{ creditScore }}
            </div>
            <div class="to-me">
              查看我的 >
            </div>
          </div>
        </button>

        <section class="quick-panel">
          <div class="quick-head">
            <h3>快捷入口</h3>
            <button class="quick-more" @click="onGotoTasks">
              去任务中心
            </button>
          </div>
          <div class="quick-grid">
            <button class="quick-item q-emerald" @click="onGotoHelp">
              <div class="q-title">我要帮忙</div>
              <div class="q-sub">浏览并接取任务</div>
            </button>
            <button class="quick-item q-green" @click="onGotoPublish">
              <div class="q-title">我要发布</div>
              <div class="q-sub">一键发布求助</div>
            </button>
            <button class="quick-item q-cyan" @click="onGotoOverview('reviews')">
              <div class="q-title">评价反馈</div>
              <div class="q-sub">查看评价记录</div>
            </button>
            <button class="quick-item q-amber" @click="onGotoOverview('stats')">
              <div class="q-title">服务统计</div>
              <div class="q-sub">查看我的进度</div>
            </button>
          </div>
        </section>

        <section class="notice-card">
          <div class="notice-head">
            <h3>社区公告</h3>
            <button @click="onViewAllAnnouncements">
              查看全部
            </button>
          </div>
          <div class="notice-list">
            <div v-if="announcementRows.length === 0" class="notice-empty">
              暂无公告（数据来自后台，已发布且您所在社区可见时显示）
            </div>
            <button
              v-for="n in announcementRows"
              :key="n.id"
              type="button"
              class="notice-item"
              @click="openAnnouncementDetail(n)"
            >
              <div class="dot" />
              <div class="text">
                {{ n.title }}
              </div>
              <div class="time">
                {{ fmtAnnounceTime(n.publishedAt || n.createdAt) }}
              </div>
              <FmIcon name="i-carbon:chevron-right" class="notice-chevron" aria-hidden="true" />
            </button>
          </div>
        </section>

        <div v-if="loading" class="status-text">
          加载中...
        </div>
        <div v-else-if="error" class="status-text error">
          {{ error }}
        </div>
        <div class="safe-space" />
      </main>

      <!-- 社区绑定已改为邀请码/扫码；不再提供“直接切换社区”抽屉 -->

      <NutPopup
        v-model:visible="showAnnouncementModal"
        position="center"
        round
        closeable
        :close-on-click-overlay="true"
        class="announce-popup-wrap"
        :style="{ width: 'min(92vw, 420px)', padding: 0 }"
      >
        <div class="announce-modal">
          <div class="announce-modal-hero">
            <div class="announce-modal-badge">
              <FmIcon name="i-carbon:notification-filled" />
              社区公告
            </div>
            <h3 class="announce-modal-title">
              {{ announcementDetail?.title || announcementListItem?.title || '公告详情' }}
            </h3>
            <div
              v-if="announcementDetail || announcementListItem"
              class="announce-modal-meta"
            >
              <span>{{
                fmtAnnounceTime(
                  (announcementDetail || announcementListItem)?.publishedAt
                    || (announcementDetail || announcementListItem)?.createdAt,
                )
              }}</span>
              <span v-if="(announcementDetail || announcementListItem)?.publisherName">
                · {{ (announcementDetail || announcementListItem)?.publisherName }}
              </span>
            </div>
          </div>
          <div class="announce-modal-body">
            <div v-if="announcementDetailLoading" class="announce-modal-status">
              加载中…
            </div>
            <div v-else-if="announcementDetailError" class="announce-modal-status err">
              {{ announcementDetailError }}
            </div>
            <template v-else-if="announcementDetail">
              <div
                v-if="announcementDetail.contentHtml"
                class="announce-html"
                v-html="announcementDetail.contentHtml"
              />
              <div
                v-else-if="announcementDetail.contentText"
                class="announce-text"
              >
                {{ announcementDetail.contentText }}
              </div>
              <p v-else class="announce-modal-status muted">
                暂无正文
              </p>
            </template>
          </div>
        </div>
      </NutPopup>

    </div>
  </AppPageLayout>
</template>

<style scoped>
.home-page {
  position: relative;
  height: 100%;
  width: min(100vw, 430px);
  margin: 0 auto;
  background: var(--m-color-bg);
}
.biz-header { display: flex; justify-content: space-between; align-items: center; gap: 10px; padding: 12px 12px 8px; background: var(--m-color-card); }
.community-switch { display: inline-flex; align-items: center; gap: 6px; border: 0; background: transparent; font-weight: 700; padding: 0; margin: 0; min-width: 0; flex: 1; }
.community-main { font-weight: 800; color: var(--m-color-text); }
.community-tip { font-size: 11px; color: #10b981; font-weight: 700; }
.scan-btn { flex-shrink: 0; width: 40px; height: 40px; border: 1px solid var(--m-color-border); border-radius: 999px; background: var(--m-color-card); color: var(--m-color-primary); display: inline-flex; align-items: center; justify-content: center; padding: 0; position: relative; }
.scan-glyph {
  width: 17px;
  height: 17px;
  border: 2px solid #0f766e;
  border-radius: 2px;
  position: relative;
  box-sizing: border-box;
}
.scan-glyph::before,
.scan-glyph::after {
  content: '';
  position: absolute;
  width: 4px;
  height: 4px;
  background: #0f766e;
  border-radius: 1px;
}
.scan-glyph::before { left: 2px; top: 2px; box-shadow: 9px 0 0 #0f766e, 0 9px 0 #0f766e; }
.scan-glyph::after { right: 2px; bottom: 2px; }
.scan-btn:active { transform: scale(0.96); }
.ai-btn { flex-shrink: 0; height: 40px; min-width: 40px; border: 1px solid #86efac; border-radius: 999px; background: #ecfdf5; color: #166534; font-weight: 900; padding: 0 10px; }
.community-icon { color: #059669; font-size: 18px; }
.distance { font-size: var(--m-font-sub); color: var(--m-color-muted); margin-left: 2px; }

.content-scroll { overflow-y: auto; height: calc(100% - 56px); padding: 10px 12px 0; }
.hero-swiper { border-radius: 16px; overflow: hidden; height: 148px; }
.hero-swiper :deep(.nut-swiper-inner) { height: 148px; }
.hero-swiper :deep(.nut-swiper-item) { height: 148px; }
.hero-item { height: 148px; padding: 16px; color: var(--m-color-text); background: var(--m-color-primary-soft); border: 1px solid var(--m-color-border); display: flex; flex-direction: column; }
.hero-title { font-size: 20px; font-weight: 800; color: var(--m-color-primary); }
.hero-sub { margin-top: 6px; font-size: 14px; color: var(--m-color-subtext); }
.hero-user { margin-top: auto; font-size: var(--m-font-sub); color: var(--m-color-subtext); }

.account-card { margin-top: 10px; border-radius: var(--m-radius-card); background: var(--m-color-card); border: 1px solid var(--m-color-border); padding: 12px; display: flex; justify-content: space-between; align-items: center; gap: 10px; width: 100%; text-align: left; box-shadow: var(--m-shadow-card); }
.avatar-wrap { width: 46px; height: 46px; border-radius: 999px; overflow: hidden; background: #ecfdf5; color: #047857; display: inline-flex; align-items: center; justify-content: center; font-size: 28px; flex-shrink: 0; }
.avatar-wrap img { width: 100%; height: 100%; object-fit: cover; display: block; }
.account-left { min-width: 0; }
.mini-label { font-size: var(--m-font-sub); color: var(--m-color-subtext); }
.account-name { margin-top: 2px; font-size: 16px; font-weight: 800; color: var(--m-color-text); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.account-sub { margin-top: 3px; font-size: var(--m-font-sub); color: var(--m-color-muted); }
.account-right { text-align: right; }
.account-coins { margin-top: 2px; font-size: 20px; font-weight: 900; color: #047857; }
.to-me { margin-top: 2px; font-size: 12px; color: #10b981; font-weight: 700; }

.notice-card { margin-top: 10px; border-radius: var(--m-radius-card); border: 1px solid var(--m-color-border); background: var(--m-color-card); padding: 12px; box-shadow: var(--m-shadow-card); }
.notice-head { display: flex; align-items: center; justify-content: space-between; }
.notice-head h3 { margin: 0; font-size: 15px; font-weight: 900; }
.notice-head button { border: 0; background: transparent; color: #10b981; font-size: 13px; font-weight: 700; }
.notice-list { margin-top: 8px; max-height: 114px; overflow-y: auto; display: grid; gap: 6px; padding-right: 2px; }
.notice-empty { font-size: 12px; color: #9ca3af; padding: 6px 0; text-align: center; }
.notice-item {
  min-height: 36px;
  display: grid;
  grid-template-columns: 8px minmax(0, 1fr) auto 18px;
  align-items: center;
  gap: 6px;
  width: 100%;
  border: 0;
  background: transparent;
  padding: 6px 4px;
  margin: 0;
  border-radius: 10px;
  cursor: pointer;
  text-align: left;
  -webkit-tap-highlight-color: transparent;
  transition: background 0.12s ease;
}
.notice-item:active { background: #f0fdf4; }
.dot { width: 6px; height: 6px; border-radius: 999px; background: #10b981; }
.notice-item .text { font-size: 13px; color: #374151; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.notice-item .time { font-size: 11px; color: #9ca3af; padding-left: 4px; white-space: nowrap; }
.notice-chevron { color: #cbd5e1; font-size: 15px; justify-self: end; }

.announce-popup-wrap :deep(.nut-popup-content) { padding: 0; overflow: hidden; border-radius: 18px; }
.announce-modal { background: #fff; max-height: min(78vh, 640px); display: flex; flex-direction: column; }
.announce-modal-hero {
  padding: 18px 18px 14px;
  background: linear-gradient(135deg, #047857 0%, #10b981 55%, #34d399 100%);
  color: #fff;
}
.announce-modal-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  font-weight: 800;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  opacity: 0.92;
}
.announce-modal-badge :deep(svg) { font-size: 14px; }
.announce-modal-title {
  margin: 10px 0 0;
  font-size: 18px;
  font-weight: 900;
  line-height: 1.35;
  letter-spacing: -0.02em;
}
.announce-modal-meta {
  margin-top: 10px;
  font-size: 12px;
  opacity: 0.92;
  line-height: 1.4;
}
.announce-modal-body {
  flex: 1;
  min-height: 0;
  overflow-y: auto;
  padding: 16px 18px 20px;
  -webkit-overflow-scrolling: touch;
}
.announce-modal-status {
  text-align: center;
  color: #6b7280;
  font-size: 14px;
  padding: 12px 0;
}
.announce-modal-status.err { color: #dc2626; }
.announce-modal-status.muted { color: #9ca3af; }
.announce-text {
  font-size: 14px;
  line-height: 1.65;
  color: #374151;
  white-space: pre-wrap;
  word-break: break-word;
}
.announce-html {
  font-size: 14px;
  line-height: 1.65;
  color: #374151;
  word-break: break-word;
}
.announce-html :deep(p) { margin: 0.5em 0; }
.announce-html :deep(p:first-child) { margin-top: 0; }
.announce-html :deep(p:last-child) { margin-bottom: 0; }
.announce-html :deep(img) { max-width: 100%; height: auto; border-radius: 8px; }
.announce-html :deep(a) { color: #059669; }

.status-text { margin-top: 10px; color: var(--m-color-subtext); font-size: var(--m-font-body); }
.status-text.error { color: #dc2626; }

.quick-panel { margin-top: 10px; border-radius: var(--m-radius-card); border: 1px solid var(--m-color-border); background: var(--m-color-card); padding: 12px; box-shadow: var(--m-shadow-card); }
.quick-head { display: flex; align-items: center; justify-content: space-between; }
.quick-head h3 { margin: 0; font-size: 15px; font-weight: 900; }
.quick-more { border: 0; background: transparent; color: #10b981; font-size: 13px; font-weight: 800; }
.quick-grid { margin-top: 10px; display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
.quick-item {
  border: 1px solid var(--m-color-border);
  background: #fff;
  border-radius: 14px;
  padding: 12px;
  text-align: left;
  box-shadow: 0 1px 6px rgba(15, 23, 42, 0.04);
}
.q-title { font-size: 15px; font-weight: 900; color: #111827; }
.q-sub { margin-top: 4px; font-size: 12px; color: #6b7280; font-weight: 600; }
.q-emerald { background: linear-gradient(160deg, #ffffff 10%, #ecfdf5 96%); border-color: #bbf7d0; }
.q-green { background: linear-gradient(160deg, #ffffff 10%, #f0fdf4 96%); border-color: #dcfce7; }
.q-cyan { background: linear-gradient(160deg, #ffffff 10%, #ecfeff 96%); border-color: #a5f3fc; }
.q-amber { background: linear-gradient(160deg, #ffffff 10%, #fffbeb 96%); border-color: #fde68a; }

.publish-drawer { padding: 10px 16px 20px; background: #fff; border-top-left-radius: 24px; border-top-right-radius: 24px; }
.publish-drawer {
  width: min(100vw, 430px);
  margin: 0 auto;
  box-sizing: border-box;
}
.drawer-handle { width: 42px; height: 4px; border-radius: 4px; background: #d1d5db; margin: 0 auto 10px; }
.publish-drawer h3 { margin: 0 0 10px; font-size: 18px; font-weight: 900; }
.detail-content p { margin: 0 0 8px; font-size: 13px; color: #374151; }
.community-drawer { padding: 10px 16px 20px; background: #fff; border-top-left-radius: 24px; border-top-right-radius: 24px; }
.community-drawer h3 { margin: 0 0 10px; font-size: 18px; font-weight: 900; }
.community-list { display: grid; gap: 8px; }
.community-item { border: 1px solid #e5e7eb; background: #fff; border-radius: 12px; padding: 12px; display: flex; justify-content: space-between; align-items: center; }
.community-item .left { display: inline-flex; align-items: center; gap: 6px; color: #111827; font-weight: 700; }
.community-item .right { font-size: 12px; color: #6b7280; }
.community-item.active { border-color: #10b981; background: #ecfdf5; }
.form-block { margin-top: 12px; padding: 10px; border: 1px solid #e5e7eb; border-radius: 12px; background: #f9fafb; }
.label { margin-bottom: 8px; font-size: 13px; color: #6b7280; }
.urgency-choose { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; }
.urgency-choose button { border: 1px solid #d1d5db; background: #fff; border-radius: 10px; padding: 8px 0; }
.urgency-choose button.active { border-color: #10b981; color: #047857; background: #ecfdf5; font-weight: 800; }
.safe-space { height: 100px; }

:global(.dark) .home-page { background: #111827; }
:global(.dark) .biz-header { background: #1f2937; border-bottom: 1px solid #374151; }
:global(.dark) .community-switch { color: #f3f4f6; }
:global(.dark) .scan-btn { background: #064e3b; color: #6ee7b7; }
:global(.dark) .distance { color: #9ca3af; }
:global(.dark) .account-card,
:global(.dark) .notice-card,
:global(.dark) .tab-item,
:global(.dark) .req-card,
:global(.dark) .community-item,
:global(.dark) .form-block,
:global(.dark) .publish-drawer,
:global(.dark) .community-drawer { background: #1f2937; border-color: #374151; }
:global(.dark) .notice-empty { color: #6b7280; }
:global(.dark) .notice-item:active { background: rgba(16, 185, 129, 0.12); }
:global(.dark) .notice-item .text { color: #e5e7eb; }
:global(.dark) .notice-chevron { color: #4b5563; }
:global(.dark) .announce-modal { background: #1f2937; }
:global(.dark) .announce-modal-body { background: #1f2937; }
:global(.dark) .announce-text,
:global(.dark) .announce-html { color: #e5e7eb; }
:global(.dark) .announce-modal-status { color: #9ca3af; }
:global(.dark) .announce-html :deep(a) { color: #34d399; }
:global(.dark) .mini-label,
:global(.dark) .account-sub,
:global(.dark) .notice-item .time,
:global(.dark) .row-publisher,
:global(.dark) .row-2,
:global(.dark) .meta,
:global(.dark) .label { color: #9ca3af; }
:global(.dark) .account-name,
:global(.dark) .notice-head h3,
:global(.dark) .title,
:global(.dark) .community-item .left,
:global(.dark) .publish-drawer h3,
:global(.dark) .community-drawer h3 { color: #f3f4f6; }
:global(.dark) .tab-item { color: #d1d5db; }
:global(.dark) .section-head h3 { color: #f3f4f6; }
:global(.dark) .urgency-choose button { background: #111827; border-color: #4b5563; color: #d1d5db; }
::global(.dark) .quick-panel { background: #1f2937; border-color: #374151; }
::global(.dark) .quick-item { background: #111827; border-color: #374151; }
::global(.dark) .q-title { color: #f3f4f6; }
::global(.dark) .q-sub { color: #9ca3af; }
::global(.dark) .q-emerald { background: linear-gradient(160deg, #0f172a 12%, #052e26 95%); border-color: #14532d; }
::global(.dark) .q-green { background: linear-gradient(160deg, #0f172a 12%, #112b21 95%); border-color: #14532d; }
::global(.dark) .q-cyan { background: linear-gradient(160deg, #0f172a 12%, #082f39 95%); border-color: #164e63; }
::global(.dark) .q-amber { background: linear-gradient(160deg, #0f172a 12%, #3b2b11 95%); border-color: #78350f; }
</style>
