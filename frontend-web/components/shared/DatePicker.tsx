import React from 'react';
import { Calendar } from 'lucide-react';

interface DatePickerProps {
  label: string;
  value: Date | null;
  onChange: (date: Date | null) => void;
  required?: boolean;
  className?: string;
  minDate?: Date;
  maxDate?: Date;
}

export const DatePicker: React.FC<DatePickerProps> = ({
  label,
  value,
  onChange,
  required = false,
  className = '',
  minDate,
  maxDate,
}) => {
  const formatDate = (date: Date | null): string => {
    if (!date) return '';
    return date.toISOString().split('T')[0];
  };

  const formatDisplayDate = (date: Date | null): string => {
    if (!date) return label;
    return new Intl.DateTimeFormat('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    }).format(date);
  };

  return (
    <div className={`w-full ${className}`}>
      <label className="block text-sm font-medium text-gray-700 mb-1">
        {label}
        {required && <span className="text-red-600 ml-1">*</span>}
      </label>
      <div className="relative">
        <input
          type="date"
          value={formatDate(value)}
          onChange={(e) => {
            const date = e.target.value ? new Date(e.target.value) : null;
            onChange(date);
          }}
          min={minDate ? formatDate(minDate) : undefined}
          max={maxDate ? formatDate(maxDate) : undefined}
          className="
            w-full px-3 py-2 pr-10 border border-gray-300 rounded-lg
            focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500
            text-base bg-white
          "
        />
        <Calendar className="absolute right-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400 pointer-events-none" />
      </div>
      {value && (
        <p className="mt-1 text-sm text-gray-600">{formatDisplayDate(value)}</p>
      )}
    </div>
  );
};

