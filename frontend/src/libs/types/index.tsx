export interface CostBreakdownProps {
  formData: FormData;
  multiChain: boolean;
  nextStep: () => void;
  prevStep: () => void;
}

export interface CampaignDetailsFormProps {
  formData: FormData;
  updateFormData: (updates: Partial<FormData>) => void;
  nextStep: () => void;
  prevStep: () => void;
}
export interface CampaignState {
  step: number;
  mode: "simple" | "advanced";
  formData: FormData;
  multiChain: boolean;
  selectedChains: string[];
  isDeploying: boolean;
  deploymentProgress: number;
}
export interface FormData {
  hashtag: string;
  description: string;
  duration: number;
  totalRewards: number;
  collectionName: string;
  imageUrl: string;
}