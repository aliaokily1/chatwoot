import { required, minLength } from '@vuelidate/validators';

// Elkheta: spaces are allowed while typing; they become "_" when the label is saved
// ("At Risk" → "at_risk"), since the server only accepts letters, numbers, "_" and "-".
export const normalizeLabelTitle = (str = '') =>
  str.trim().replace(/\s+/g, '_').toLowerCase();

export const validLabelCharacters = (str = '') => !!str && !!str.trim();

export const getLabelTitleErrorMessage = validation => {
  let errorMessage = '';
  if (!validation.title.$error) {
    errorMessage = '';
  } else if (!validation.title.required) {
    errorMessage = 'LABEL_MGMT.FORM.NAME.REQUIRED_ERROR';
  } else if (!validation.title.minLength) {
    errorMessage = 'LABEL_MGMT.FORM.NAME.MINIMUM_LENGTH_ERROR';
  } else if (!validation.title.validLabelCharacters) {
    errorMessage = 'LABEL_MGMT.FORM.NAME.VALID_ERROR';
  }
  return errorMessage;
};

export default {
  title: {
    required,
    minLength: minLength(2),
    validLabelCharacters,
  },
  description: {},
  color: {
    required,
  },
  showOnSidebar: {},
};
