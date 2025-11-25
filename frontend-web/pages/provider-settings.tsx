import React from 'react';
import { useRouter } from 'next/router';
import Link from 'next/link';
import { 
  Edit, 
  FileText,
  Stars,
  UserCircle,
  LogOut,
  ArrowRight
} from 'lucide-react';

const ProviderSettingsPage: React.FC = () => {
  const router = useRouter();
  const { providerId } = router.query;

  const handleLogout = async () => {
    if (window.confirm('Are you sure you want to logout?')) {
      localStorage.removeItem('token');
      localStorage.removeItem('providerId');
      window.location.href = '/login';
    }
  };

  const settingsCards = [
    {
      title: 'Edit Our Services',
      subtitle: 'Manage your services, pricing, and service requirements',
      icon: Edit,
      color: 'blue',
      route: `/provider/edit-provider?providerId=${providerId}`,
      isComingSoon: false,
    },
    {
      title: 'Manage Templates',
      subtitle: 'Create and manage service templates for quick booking',
      icon: FileText,
      color: 'green',
      route: `/provider/manage-templates?providerId=${providerId}`,
      isComingSoon: false,
    },
    {
      title: 'Loyalty Program',
      subtitle: 'Manage your loyalty program participation and settings',
      icon: Stars,
      color: 'purple',
      route: `/provider/loyalty?providerId=${providerId}`,
      isComingSoon: true,
    },
    {
      title: 'Account Settings',
      subtitle: 'Manage your account preferences and notifications',
      icon: UserCircle,
      color: 'orange',
      route: `/provider/account?providerId=${providerId}`,
      isComingSoon: true,
    },
    {
      title: 'Logout',
      subtitle: 'Sign out of your provider account',
      icon: LogOut,
      color: 'red',
      onClick: handleLogout,
      isComingSoon: false,
    },
  ];

  const getColorClasses = (color: string) => {
    const colorMap: Record<string, { bg: string; text: string }> = {
      blue: { bg: 'bg-blue-100', text: 'text-blue-600' },
      green: { bg: 'bg-green-100', text: 'text-green-600' },
      purple: { bg: 'bg-purple-100', text: 'text-purple-600' },
      orange: { bg: 'bg-orange-100', text: 'text-orange-600' },
      red: { bg: 'bg-red-100', text: 'text-red-600' },
    };
    return colorMap[color] || colorMap.blue;
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-50 via-blue-50 to-cyan-50">
      <div className="safe-area">
        <div className="p-5">
          <h1 className="text-2xl font-bold text-gray-800 mb-2">Provider Settings</h1>
          <p className="text-gray-600 mb-6">Manage your provider account and services</p>

          <div className="space-y-4">
            {settingsCards.map((card, index) => {
              const IconComponent = card.icon;
              const colors = getColorClasses(card.color);

              // Safety check: ensure icon component exists
              if (!IconComponent) {
                console.error(`Icon component is undefined for card: ${card.title}`);
              }

              const handleClick = () => {
                if (card.isComingSoon) {
                  alert(`${card.title} is coming soon!`);
                  return;
                }
                if (card.onClick) {
                  card.onClick();
                } else if (card.route) {
                  router.push(card.route);
                }
              };

              return (
                <div
                  key={index}
                  onClick={handleClick}
                  className="bg-white rounded-2xl shadow-lg p-5 cursor-pointer hover:shadow-xl transition-shadow"
                >
                  <div className="flex items-center space-x-4">
                    <div className={`p-3 rounded-xl ${colors.bg}`}>
                      {IconComponent ? (
                        <IconComponent className={`h-6 w-6 ${colors.text}`} />
                      ) : (
                        <div className={`h-6 w-6 ${colors.text} rounded`} />
                      )}
                    </div>
                    <div className="flex-1">
                      <h3 className="font-bold text-gray-900">{card.title}</h3>
                      <p className="text-sm text-gray-600">{card.subtitle}</p>
                      {card.isComingSoon && (
                        <span className="text-xs text-orange-600 font-medium">Coming Soon</span>
                      )}
                    </div>
                    <ArrowRight className="h-5 w-5 text-gray-400" />
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
};

export default ProviderSettingsPage;

