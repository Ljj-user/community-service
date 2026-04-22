import React from 'react'
import {
  User,
  Heart,
  ShieldCheck,
  Settings,
  CheckCircle2,
  BarChart3,
  Lock,
  Sparkles,
  Zap,
  LayoutGrid,
} from 'lucide-react'

const FunctionalMap = () => {
  const RoleCard = ({
    icon: Icon,
    title,
    subtitle,
    color,
    functions,
    extensions,
  }: {
    icon: React.ComponentType<{ className?: string }>
    title: string
    subtitle: string
    color: string
    functions: string[]
    extensions?: string[]
  }) => (
    <div className={`p-6 rounded-2xl border-2 ${color} bg-white/[.41] backdrop-blur-md shadow-lg h-full transition-all hover:shadow-xl hover:bg-white/60`}>
      <div className="flex items-center gap-3 mb-4">
        <div className={`p-3 rounded-xl bg-opacity-20 ${color.replace('border', 'bg').replace('200', '100')}`}>
          <Icon className={`w-6 h-6 ${color.replace('border-', 'text-').replace('-200', '-600')}`} />
        </div>
        <div>
          <h3 className="text-lg font-bold text-gray-800">{title}</h3>
          <p className="text-[10px] text-gray-400 uppercase tracking-widest font-bold">{subtitle}</p>
        </div>
      </div>

      <div className="space-y-4">
        <div>
          <div className="text-[11px] font-bold text-gray-400 mb-2 border-b border-gray-200/50 pb-1">核心业务能力</div>
          <ul className="grid grid-cols-1 gap-1.5">
            {functions.map((f, i) => (
              <li key={i} className="flex items-start gap-2 text-[12px] text-gray-700 font-medium">
                <CheckCircle2 className="w-3.5 h-3.5 mt-0.5 text-emerald-500 shrink-0" />
                <span>{f}</span>
              </li>
            ))}
          </ul>
        </div>

        {extensions && (
          <div className="pt-2">
            <div className="text-[11px] font-bold text-amber-600 mb-2 border-b border-amber-200/50 pb-1 flex items-center gap-1">
              <Sparkles className="w-3 h-3" /> 设想与扩展需求
            </div>
            <ul className="grid grid-cols-1 gap-1.5">
              {extensions.map((f, i) => (
                <li key={i} className="flex items-start gap-2 text-[11px] text-amber-700/90 italic leading-tight font-medium">
                  <Zap className="w-3 h-3 mt-0.5 shrink-0" />
                  <span>{f}</span>
                </li>
              ))}
            </ul>
          </div>
        )}
      </div>
    </div>
  )

  return (
    <div className="min-h-screen bg-slate-100 p-8 font-sans relative overflow-hidden">
      <div className="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] bg-blue-400/10 rounded-full blur-3xl"></div>
      <div className="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] bg-rose-400/10 rounded-full blur-3xl"></div>

      <div className="max-w-6xl mx-auto relative z-10">
        <div className="text-center mb-10">
          <h1 className="text-3xl font-black text-slate-800 flex items-center justify-center gap-3">
            <BarChart3 className="w-8 h-8 text-blue-600" />
            系统功能角色架构分布图
          </h1>
          <p className="text-slate-500 mt-2 font-medium">基于居民、志愿者、社区及系统管理四位一体的功能设计</p>
          <div className="w-32 h-1 bg-blue-600 mx-auto mt-4 rounded-full shadow-lg shadow-blue-500/50"></div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          <RoleCard
            icon={User}
            title="居民（需求方）"
            subtitle="Residents / Demanders"
            color="border-blue-200/60 text-blue-600"
            functions={[
              '账号资料与社区归属绑定',
              '服务需求发布（含类型/紧急度/地址）',
              '全流程进度追踪与审核反馈查看',
              '评价反馈与历史服务记录查询',
              '网格化社区公告定向获取',
            ]}
            extensions={[
              '需求撤回与二次修改逻辑',
              '多通道消息通知（审核/领单提醒）',
            ]}
          />

          <RoleCard
            icon={Heart}
            title="志愿者（服务方）"
            subtitle="Volunteers / Providers"
            color="border-rose-200/60 text-rose-600"
            functions={[
              '多维技能标签维护（画像基础）',
              '任务大厅筛选与认领（防并发冲突）',
              '领单状态管理与服务详情查看',
              '时长统计与服务成效评价查看',
              '累计积分与星级勋章展示',
            ]}
            extensions={[
              '智能推荐列表（基于技能与距离）',
              '信用评价体系与等级成长树',
            ]}
          />

          <RoleCard
            icon={ShieldCheck}
            title="社区管理员（运营）"
            subtitle="Community Admins / Ops"
            color="border-emerald-200/60 text-emerald-600"
            functions={[
              '辖区内需求合规性审核与驳回',
              '全量业务进度监管与异常预警',
              '网格化公告精准推送与置顶管理',
              '运营数据多维统计（对接成功率等）',
              '多格式业务数据导出与报表归档',
            ]}
            extensions={[
              '基于历史趋势的资源调度建议',
              '智慧运营大屏与自动化月报生成',
            ]}
          />

          <RoleCard
            icon={Settings}
            title="超级管理员（治理）"
            subtitle="Super Admins / Governance"
            color="border-slate-300/60 text-slate-600"
            functions={[
              '系统核心参数配置（配置中心）',
              '网格树结构维护与基础设施初始化',
              '全局用户管控与精细化权限分配',
              '全站级关键操作审计日志追踪',
              '系统级数据备份与容灾恢复管理',
            ]}
            extensions={[
              '系统运行状态实时监控告警',
              '完善的 JWT/Redis 安全防攻击策略',
            ]}
          />
        </div>

        <div className="mt-12 flex justify-center items-center gap-10 text-[11px] font-bold text-slate-500 uppercase tracking-widest">
          <div className="flex items-center gap-2">
            <LayoutGrid className="w-4 h-4" /> 统一后端支撑
          </div>
          <div className="flex items-center gap-2">
            <Lock className="w-4 h-4" /> 权限边界控制
          </div>
          <div className="flex items-center gap-2">
            <Sparkles className="w-4 h-4 text-amber-500" /> AI 持续赋能
          </div>
        </div>
      </div>
    </div>
  )
}

export default FunctionalMap

