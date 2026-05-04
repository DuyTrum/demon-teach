/**
 * Content Validator
 * Validates lesson content structure according to the schema
 * Integrates with ContentParser from Flutter app
 */

class ContentValidator {
  /**
   * Validate complete lesson content
   * @param {Object} content - Lesson content object
   * @returns {Object} - { isValid: boolean, errors: string[] }
   */
  static validate(content) {
    const errors = [];

    if (!content || typeof content !== 'object') {
      errors.push('Content must be a valid object');
      return { isValid: false, errors };
    }

    // Validate required fields
    if (!content.flashcards) {
      errors.push('Missing required field: flashcards');
    } else {
      const flashcardErrors = this.validateFlashcards(content.flashcards);
      errors.push(...flashcardErrors);
    }

    if (!content.quiz) {
      errors.push('Missing required field: quiz');
    } else {
      const quizErrors = this.validateQuiz(content.quiz);
      errors.push(...quizErrors);
    }

    // Validate optional fields
    if (content.listeningExercise) {
      const listeningErrors = this.validateListeningExercise(content.listeningExercise);
      errors.push(...listeningErrors);
    }

    if (content.speakingExercise) {
      const speakingErrors = this.validateSpeakingExercise(content.speakingExercise);
      errors.push(...speakingErrors);
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  /**
   * Validate flashcards array
   */
  static validateFlashcards(flashcards) {
    const errors = [];

    if (!Array.isArray(flashcards)) {
      errors.push('flashcards must be an array');
      return errors;
    }

    if (flashcards.length === 0) {
      errors.push('flashcards array cannot be empty');
      return errors;
    }

    flashcards.forEach((card, index) => {
      const prefix = `flashcards[${index}]`;

      if (!card.id) errors.push(`${prefix}: missing required field 'id'`);
      if (!card.lessonId) errors.push(`${prefix}: missing required field 'lessonId'`);
      if (!card.frontText) errors.push(`${prefix}: missing required field 'frontText'`);
      if (!card.backText) errors.push(`${prefix}: missing required field 'backText'`);
      if (!card.exampleUsage) errors.push(`${prefix}: missing required field 'exampleUsage'`);

      // Validate audioUrl if present
      if (card.audioUrl && !this.isValidUrl(card.audioUrl)) {
        errors.push(`${prefix}: audioUrl is not a valid URL`);
      }
    });

    return errors;
  }

  /**
   * Validate quiz object
   */
  static validateQuiz(quiz) {
    const errors = [];

    if (!quiz.id) errors.push('quiz: missing required field \'id\'');
    if (!quiz.lessonId) errors.push('quiz: missing required field \'lessonId\'');
    if (!quiz.title) errors.push('quiz: missing required field \'title\'');

    if (!quiz.questions) {
      errors.push('quiz: missing required field \'questions\'');
      return errors;
    }

    if (!Array.isArray(quiz.questions)) {
      errors.push('quiz.questions must be an array');
      return errors;
    }

    if (quiz.questions.length === 0) {
      errors.push('quiz.questions array cannot be empty');
      return errors;
    }

    quiz.questions.forEach((question, index) => {
      const prefix = `quiz.questions[${index}]`;

      if (!question.id) errors.push(`${prefix}: missing required field 'id'`);
      if (!question.type) errors.push(`${prefix}: missing required field 'type'`);
      if (!question.questionText) errors.push(`${prefix}: missing required field 'questionText'`);
      if (!question.correctAnswer) errors.push(`${prefix}: missing required field 'correctAnswer'`);

      // Validate question type
      const validTypes = ['multipleChoice', 'fillInBlank', 'matching', 'trueFalse'];
      if (question.type && !validTypes.includes(question.type)) {
        errors.push(`${prefix}: invalid question type '${question.type}'. Must be one of: ${validTypes.join(', ')}`);
      }

      // Validate options for multiple choice
      if (question.type === 'multipleChoice') {
        if (!question.options || !Array.isArray(question.options)) {
          errors.push(`${prefix}: multiple choice questions must have 'options' array`);
        } else if (question.options.length < 2) {
          errors.push(`${prefix}: multiple choice questions must have at least 2 options`);
        }
      }
    });

    return errors;
  }

  /**
   * Validate listening exercise
   */
  static validateListeningExercise(exercise) {
    const errors = [];

    if (!exercise.id) errors.push('listeningExercise: missing required field \'id\'');
    if (!exercise.lessonId) errors.push('listeningExercise: missing required field \'lessonId\'');
    if (!exercise.audioUrl) errors.push('listeningExercise: missing required field \'audioUrl\'');
    if (!exercise.durationSeconds) errors.push('listeningExercise: missing required field \'durationSeconds\'');

    // Validate audioUrl
    if (exercise.audioUrl && !this.isValidUrl(exercise.audioUrl)) {
      errors.push('listeningExercise: audioUrl is not a valid URL');
    }

    // Validate duration
    if (exercise.durationSeconds && (exercise.durationSeconds < 10 || exercise.durationSeconds > 60)) {
      errors.push('listeningExercise: durationSeconds must be between 10 and 60 seconds');
    }

    // Validate questions
    if (!exercise.questions) {
      errors.push('listeningExercise: missing required field \'questions\'');
    } else if (!Array.isArray(exercise.questions)) {
      errors.push('listeningExercise.questions must be an array');
    } else if (exercise.questions.length < 3 || exercise.questions.length > 5) {
      errors.push('listeningExercise: must have 3-5 comprehension questions');
    } else {
      exercise.questions.forEach((question, index) => {
        const prefix = `listeningExercise.questions[${index}]`;
        if (!question.questionText) errors.push(`${prefix}: missing required field 'questionText'`);
        if (!question.options || !Array.isArray(question.options)) {
          errors.push(`${prefix}: missing required field 'options' array`);
        }
        if (!question.correctAnswer) errors.push(`${prefix}: missing required field 'correctAnswer'`);
      });
    }

    return errors;
  }

  /**
   * Validate speaking exercise
   */
  static validateSpeakingExercise(exercise) {
    const errors = [];

    if (!exercise.id) errors.push('speakingExercise: missing required field \'id\'');
    if (!exercise.lessonId) errors.push('speakingExercise: missing required field \'lessonId\'');
    if (!exercise.phrase) errors.push('speakingExercise: missing required field \'phrase\'');
    if (!exercise.modelAudioUrl) errors.push('speakingExercise: missing required field \'modelAudioUrl\'');

    // Validate modelAudioUrl
    if (exercise.modelAudioUrl && !this.isValidUrl(exercise.modelAudioUrl)) {
      errors.push('speakingExercise: modelAudioUrl is not a valid URL');
    }

    return errors;
  }

  /**
   * Validate URL format
   */
  static isValidUrl(url) {
    try {
      const urlObj = new URL(url);
      return urlObj.protocol === 'http:' || urlObj.protocol === 'https:';
    } catch (e) {
      return false;
    }
  }

  /**
   * Validate metadata
   */
  static validateMetadata(metadata) {
    const errors = [];

    if (!metadata || typeof metadata !== 'object') {
      errors.push('Metadata must be a valid object');
      return { isValid: false, errors };
    }

    if (!metadata.title) errors.push('metadata: missing required field \'title\'');
    if (!metadata.difficulty) errors.push('metadata: missing required field \'difficulty\'');
    if (!metadata.topic) errors.push('metadata: missing required field \'topic\'');
    if (!metadata.targetLanguage) errors.push('metadata: missing required field \'targetLanguage\'');
    if (!metadata.durationEstimate) errors.push('metadata: missing required field \'durationEstimate\'');

    // Validate difficulty
    const validDifficulties = ['basic', 'intermediate', 'advanced'];
    if (metadata.difficulty && !validDifficulties.includes(metadata.difficulty)) {
      errors.push(`metadata: invalid difficulty '${metadata.difficulty}'. Must be one of: ${validDifficulties.join(', ')}`);
    }

    // Validate targetLanguage
    const validLanguages = ['en', 'zh', 'ko'];
    if (metadata.targetLanguage && !validLanguages.includes(metadata.targetLanguage)) {
      errors.push(`metadata: invalid targetLanguage '${metadata.targetLanguage}'. Must be one of: ${validLanguages.join(', ')}`);
    }

    // Validate durationEstimate
    if (metadata.durationEstimate && (metadata.durationEstimate < 5 || metadata.durationEstimate > 30)) {
      errors.push('metadata: durationEstimate must be between 5 and 30 minutes');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }
}

module.exports = ContentValidator;
