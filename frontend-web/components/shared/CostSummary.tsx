import React from 'react';
import { DollarSign } from 'lucide-react';

interface Service {
  display_name: string;
  done: boolean;
  cost?: string | number;
}

interface CostSummaryProps {
  services: Service[];
}

export const CostSummary: React.FC<CostSummaryProps> = ({ services }) => {
  const completedServices = services.filter(s => s.done === true);
  
  const calculateTotal = (): number => {
    return completedServices.reduce((total, service) => {
      const cost = typeof service.cost === 'string' 
        ? parseFloat(service.cost) || 0 
        : (service.cost || 0);
      return total + cost;
    }, 0);
  };

  const totalCost = calculateTotal();

  if (completedServices.length === 0) {
    return null;
  }

  return (
    <div className="bg-green-50 border border-green-200 rounded-lg p-4">
      <div className="flex items-center gap-2 mb-3">
        <DollarSign className="w-4 h-4 text-green-700" />
        <h3 className="text-sm font-bold text-green-700">Cost Summary</h3>
      </div>
      
      <div className="space-y-2 mb-3">
        {completedServices.map((service, index) => {
          const cost = typeof service.cost === 'string' 
            ? parseFloat(service.cost) || 0 
            : (service.cost || 0);
          
          return (
            <div key={index} className="flex justify-between items-center text-xs">
              <span className="text-green-600">{service.display_name}</span>
              <span className="font-bold text-green-700">KES {cost.toFixed(0)}</span>
            </div>
          );
        })}
      </div>
      
      <div className="pt-3 border-t border-green-200 flex justify-between items-center">
        <span className="text-sm text-green-600">
          Completed Services: {completedServices.length}
        </span>
        <span className="text-base font-bold text-green-700">
          Total: KES {totalCost.toFixed(0)}
        </span>
      </div>
    </div>
  );
};

