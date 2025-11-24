import React from 'react';
import { CheckCircle2, Circle } from 'lucide-react';

interface ServiceItemProps {
  index: number;
  service: {
    service_id: string;
    display_name: string;
    done: boolean;
    notes: string;
    cost?: string | number;
  };
  onToggleDone: (index: number, done: boolean) => void;
  onNotesChange: (index: number, notes: string) => void;
  onCostChange: (index: number, cost: string) => void;
  costController?: string;
}

export const ServiceItem: React.FC<ServiceItemProps> = ({
  index,
  service,
  onToggleDone,
  onNotesChange,
  onCostChange,
  costController = '',
}) => {
  const isCompleted = service.done === true;

  return (
    <div
      className={`
        border rounded-lg transition-all
        ${isCompleted 
          ? 'bg-green-50 border-green-300 border-2' 
          : 'bg-white border-gray-300'
        }
      `}
    >
      <div className="p-3">
        <div className="flex items-center gap-3 mb-3">
          <button
            type="button"
            onClick={() => onToggleDone(index, !isCompleted)}
            className="flex-shrink-0"
          >
            {isCompleted ? (
              <CheckCircle2 className="w-6 h-6 text-green-600" />
            ) : (
              <Circle className="w-6 h-6 text-gray-400" />
            )}
          </button>
          <label className="flex-1 cursor-pointer">
            <input
              type="checkbox"
              checked={isCompleted}
              onChange={(e) => onToggleDone(index, e.target.checked)}
              className="sr-only"
            />
            <span
              className={`
                text-sm font-medium
                ${isCompleted ? 'text-green-800 font-bold' : 'text-gray-800'}
              `}
            >
              {service.display_name}
            </span>
          </label>
        </div>
        
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label className="block text-xs font-medium text-gray-600 mb-1">
              Cost (KES)
            </label>
            <div className="relative">
              <span className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-500 text-sm">
                KES
              </span>
              <input
                type="number"
                value={costController}
                onChange={(e) => onCostChange(index, e.target.value)}
                placeholder="0"
                className="
                  w-full pl-12 pr-3 py-2 border border-gray-300 rounded-lg
                  focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500
                  text-sm
                "
              />
            </div>
          </div>
          
          <div>
            <label className="block text-xs font-medium text-gray-600 mb-1">
              Notes (optional)
            </label>
            <input
              type="text"
              value={service.notes}
              onChange={(e) => onNotesChange(index, e.target.value)}
              placeholder="Add notes..."
              className="
                w-full px-3 py-2 border border-gray-300 rounded-lg
                focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500
                text-sm
              "
            />
          </div>
        </div>
      </div>
    </div>
  );
};

