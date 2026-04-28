<script setup lang="ts">
import {
  PersonSettings20Regular as AccountSettingsIcon,
  PersonSettings20Filled as AccountSettingsIconActive,
  CheckmarkStarburst20Regular as BrandsIcon,
  CheckmarkStarburst20Filled as BrandsIconActive,
  DataTrending16Regular as ChartsIcon,
  Dismiss24Filled as CloseIcon,
  People24Regular as CustomersIcon,
  People24Filled as CustomersIconActive,
  Board24Regular as DashboardIcon,
  ChartMultiple20Filled as DashboardIcon1Active,
  ArrowTrendingLines24Regular as DashboardIcon2,
  Table28Regular as DataIcon,
  Table28Filled as DataIconActive,
  ErrorCircle24Regular as ErrorIcon,
  Cart24Regular as eCommerceIcon,
  FormNew24Regular as FormsIcon,
  DocumentLink20Regular as PagesIcon,
  StarThreeQuarter20Filled as ReviewIcon,
  Settings28Regular as SettingsIcon,
  CheckmarkCircle24Regular as TodoAppIcon,
  CheckmarkCircle24Filled as TodoAppIconActive,
} from '@vicons/fluent'
import { storeToRefs } from 'pinia'
import type { SidebarMenuOption } from './SidebarMenu.vue'

const layoutStore = useLayoutStore()
const { collapsed, forceCollapsed, mobileMode, mobileMenuClosed } = storeToRefs(layoutStore)
const { t, locale } = useI18n()
const accountStore = useAccountStore()
const { user } = storeToRefs(accountStore)

const homeBoardLabel = computed(() => {
  const role = user.value?.role
  const identityType = user.value?.identityType
  if (role === 1 || role === 2)
    return t('menu.homeBoardAdmin')
  if (role === 3 && identityType === 2)
    return t('menu.homeBoardVolunteer')
  return t('menu.homeBoardResident')
})

const homeBoardItem = computed<SidebarMenuOption>(() => ({
  label: homeBoardLabel.value,
  route: '/dashboard',
  key: 'dashboard-home',
  icon: DashboardIcon,
  activeIcon: DashboardIcon1Active,
}))

const effectiveCollapsed = computed(() => {
  if (mobileMode.value) return mobileMenuClosed.value
  return collapsed.value || forceCollapsed.value
})

function buildSettingsSubmenu(): SidebarMenuOption {
  return {
    label: t('menu.settings'),
    key: 'settings',
    icon: SettingsIcon,
    children: [
      {
        label: t('menu.accountSettings'),
        route: '/account/profile',
        key: 'account-profile',
        icon: AccountSettingsIcon,
        activeIcon: AccountSettingsIconActive,
      },
    ],
  }
}

const superAdminMenuOptions = computed<SidebarMenuOption[]>(() => {
  void locale.value
  return [
    homeBoardItem.value,
    {
      label: t('menu.adminOpsGroup'),
      key: 'group-admin-ops',
      icon: CustomersIcon,
      activeIcon: CustomersIconActive,
      children: [
        {
          label: t('menu.admin-users'),
          route: '/admin/users',
          key: 'admin-users',
          icon: CustomersIcon,
          activeIcon: CustomersIconActive,
        },
        {
          label: t('menu.communityRequests'),
          route: '/community/requests',
          key: 'communityRequests',
          icon: ErrorIcon,
        },
        {
          label: t('menu.communityVolunteers'),
          route: '/community/volunteers',
          key: 'communityVolunteers',
          icon: CustomersIcon,
          activeIcon: CustomersIconActive,
        },
        {
          label: t('menu.communityMonitor'),
          route: '/community/monitor',
          key: 'communityMonitor',
          icon: DashboardIcon2,
        },
        {
          label: t('menu.communityAnnouncements'),
          route: '/community/announcements',
          key: 'communityAnnouncements',
          icon: PagesIcon,
        },
        {
          label: t('menu.communityInviteCodes'),
          route: '/community/invite-codes',
          key: 'communityInviteCodes',
          icon: FormsIcon,
          activeIcon: FormsIcon,
        },
        {
          label: t('menu.communityBanners'),
          route: '/community/banners',
          key: 'communityBanners',
          icon: BrandsIcon,
          activeIcon: BrandsIconActive,
        },
      ],
    },
    {
      label: t('menu.adminSystemGroup'),
      key: 'group-admin-sys',
      icon: DataIcon,
      activeIcon: DataIconActive,
      children: [
        {
          label: t('menu.admin-audit'),
          route: '/admin/audit',
          key: 'admin-audit',
          icon: ErrorIcon,
        },
        {
          label: t('menu.admin-global-dashboard'),
          route: '/admin/global-dashboard',
          key: 'admin-global-dashboard',
          icon: ChartsIcon,
        },
        {
          label: t('menu.admin-config'),
          route: '/admin/config',
          key: 'admin-config',
          icon: SettingsIcon,
        },
        {
          label: t('menu.admin-backup'),
          route: '/admin/backup',
          key: 'admin-backup',
          icon: DataIcon,
          activeIcon: DataIconActive,
        },
      ],
    },
    buildSettingsSubmenu(),
  ]
})

const communityAdminMenuOptions = computed<SidebarMenuOption[]>(() => {
  void locale.value
  return [
    homeBoardItem.value,
    {
      label: t('menu.adminOpsGroup'),
      key: 'group-admin-ops',
      icon: CustomersIcon,
      activeIcon: CustomersIconActive,
      children: [
        {
          label: t('menu.communityScopedUsers'),
          route: '/admin/users',
          key: 'community-users',
          icon: CustomersIcon,
          activeIcon: CustomersIconActive,
        },
        {
          label: t('menu.communityRequests'),
          route: '/community/requests',
          key: 'communityRequests',
          icon: ErrorIcon,
        },
        {
          label: t('menu.communityVolunteers'),
          route: '/community/volunteers',
          key: 'communityVolunteers',
          icon: CustomersIcon,
          activeIcon: CustomersIconActive,
        },
        {
          label: t('menu.communityMonitor'),
          route: '/community/monitor',
          key: 'communityMonitor',
          icon: DashboardIcon2,
        },
        {
          label: t('menu.communityAnnouncements'),
          route: '/community/announcements',
          key: 'communityAnnouncements',
          icon: PagesIcon,
        },
        {
          label: t('menu.communityInviteCodes'),
          route: '/community/invite-codes',
          key: 'communityInviteCodes',
          icon: FormsIcon,
          activeIcon: FormsIcon,
        },
        {
          label: t('menu.communityBanners'),
          route: '/community/banners',
          key: 'communityBanners',
          icon: BrandsIcon,
          activeIcon: BrandsIconActive,
        },
        {
          label: t('menu.communityAudit'),
          route: '/admin/audit',
          key: 'community-audit',
          icon: ErrorIcon,
        },
      ],
    },
    buildSettingsSubmenu(),
  ]
})

const userMenuOptions = computed<SidebarMenuOption[]>(() => {
  void locale.value
  const identityType = user.value?.identityType
  const options: SidebarMenuOption[] = []

  options.push(homeBoardItem.value)

  const announcementOption: SidebarMenuOption = {
    label: t('menu.user-announcements'),
    route: '/user/announcements',
    key: 'user-announcements',
    icon: PagesIcon,
  }

  if (identityType === 1) {
    options.push({
      label: t('menu.residentServicesGroup'),
      key: 'group-resident',
      icon: DashboardIcon,
      children: [
        {
          label: t('menu.userResident'),
          route: '/user/resident',
          key: 'user-resident',
          icon: DashboardIcon,
        },
        {
          label: t('menu.request-create'),
          route: '/request/create',
          key: 'request-create',
          icon: FormsIcon,
        },
        {
          label: t('menu.request-my'),
          route: '/request/my',
          key: 'request-my',
          icon: TodoAppIcon,
          activeIcon: TodoAppIconActive,
        },
        {
          label: t('menu.request-evaluations'),
          route: '/request/evaluations',
          key: 'request-evaluations',
          icon: ReviewIcon,
        },
      ],
    })
  }

  if (identityType === 2) {
    options.push({
      label: t('menu.volunteerServicesGroup'),
      key: 'group-volunteer',
      icon: DashboardIcon,
      activeIcon: DashboardIcon1Active,
      children: [
        {
          label: t('menu.userVolunteer'),
          route: '/user/volunteer',
          key: 'user-volunteer',
          icon: DashboardIcon,
          activeIcon: DashboardIcon1Active,
        },
        {
          label: t('menu.service-market'),
          route: '/service/market',
          key: 'service-market',
          icon: eCommerceIcon,
        },
        {
          label: t('menu.service-my-records'),
          route: '/service/my-records',
          key: 'service-my-records',
          icon: ChartsIcon,
        },
        {
          label: t('menu.service-my-evaluations'),
          route: '/service/my-evaluations',
          key: 'service-my-evaluations',
          icon: ReviewIcon,
        },
      ],
    })
  }

  options.push(announcementOption)
  options.push(buildSettingsSubmenu())
  return options
})

const menuOptions = computed<SidebarMenuOption[]>(() => {
  const role = user.value?.role

  if (role === 3)
    return userMenuOptions.value

  if (role === 1)
    return superAdminMenuOptions.value

  return communityAdminMenuOptions.value
})

const router = useRouter()
router.beforeEach(() => {
  layoutStore.closeSidebar()
})
</script>

<template>
  <n-layout-sider :native-scrollbar="false" collapse-mode="width" :collapsed-width="mobileMode ? 0 : 64"
    :collapsed="effectiveCollapsed"
    :class="{ 'collapsed': effectiveCollapsed, 'mobile-mode': mobileMode, 'support-mode': layoutStore.supportEnabled }">
    <div class="logo-container mb-4">
      <div flex w-full justify-between items-center>
        <div flex w-full justify-start items-center>
          <div class="logo-bg"><img src="@/assets/images/logo.png" alt="logo" class="logo"></div>
          <h1 class="main-title">
            {{ t('title') }}
          </h1>
        </div>

        <n-button v-if="mobileMode" mx-2 size="small" tertiary circle @click="layoutStore.closeSidebar">
          <template #icon>
            <NIcon size="1.2rem">
              <CloseIcon />
            </NIcon>
          </template>
        </n-button>
      </div>
    </div>
    <SidebarMenu :collapsed-width="mobileMode ? 0 : 64" :collapsed-icon-size="mobileMode ? 30 : 20"
      :options="menuOptions" />
  </n-layout-sider>
</template>

<style lang="scss">
.n-scrollbar {
  z-index: 1;
}

.logo-container {
  display: flex;
  align-items: center;
  padding: 1.5rem 0.8rem 0.5rem 1.1rem;
  transition: all 100ms;
  line-height: 1;

  .main-title {
    font-family: Quicksand, Shabnam;
    font-size: 1.3rem;
    font-weight: 500;
    user-select: none;
  }

  .logo-bg {
    width: 38px;
    height: 38px;
    display: flex;
    margin: 0 .34rem;
    justify-content: center;
    align-items: center;

    .logo {
      width: 34px;
      object-fit: cover;
    }
  }

  .text-logo {
    max-width: 175px;
  }
}

.mobile-mode {
  max-width: 100% !important;
  width: 100% !important;
}

.mobile-mode.collapsed {
  max-width: 0 !important;
}

.collapsed {
  .logo-container {
    padding: 1.5rem 0.5rem 0.5rem .5rem;
  }

  .main-title {
    display: none;
  }

  .n-menu-item-group>.n-menu-item-group-title {
    display: none;
  }

  .p-button-label {
    display: none;
  }
}

.n-menu .n-menu-item-content:not(.n-menu-item-content--disabled):hover::before {
  background-color: rgba(189, 189, 189, 0.15);
}

.n-menu-tooltip span {
  color: #e4e4e4 !important;
}

.n-layout-sider {
  background-color: transparent;
}

.p-button {
  .p-button-label {
    text-align: left;
  }
}

.rtl {
  .logo {
    margin-left: 0.8rem;
    margin-right: .5rem;
  }

  .n-menu-item-group-title {
    margin-left: auto;
    margin-right: 32px;
  }
}

.support-mode {
  .n-scrollbar>.n-scrollbar-container {
    max-height: calc(100% - 120px);
  }
}

.n-menu-item {
  user-select: none;
}

.main-menu {
  .active {
    .p-button {

      .p-button-label,
      .p-button-icon {
        color: var(--primary-color);
      }
    }

    ul>li>a {
      display: block;
    }
  }

  .separator {
    border-bottom: solid 1px #f4f4f5;
    margin-bottom: .5rem;
  }
}

.p-sidebar-header {
  justify-content: center;
  font-weight: bold;
  padding-top: 1.7rem !important;
}

.p-sidebar-header-content {
  width: 100%;
}

.n-menu-item-group .n-submenu .n-menu-item-content.n-menu-item-content--collapsed {
  padding-left: 22px !important;
}

.n-menu .n-menu-item-group .n-menu-item-group-title {
  height: 20px;
}
</style>
