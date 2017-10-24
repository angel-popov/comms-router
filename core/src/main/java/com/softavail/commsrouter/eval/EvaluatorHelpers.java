/*
 * To change this license header, choose License Headers in Project Properties. To change this
 * template file, choose Tools | Templates and open the template in the editor.
 */

package com.softavail.commsrouter.eval;

import net.sourceforge.jeval.EvaluationConstants;
import net.sourceforge.jeval.EvaluationException;
import net.sourceforge.jeval.function.FunctionException;
import net.sourceforge.jeval.function.FunctionHelper;

/**
 *
 * @author ergyunsyuleyman
 */
public class EvaluatorHelpers {

  private static String openBracketCharacter = "[";
  private static String closeBracketCharacter = "]";
  public static String VALIDATION_VARIABLE_VALUE =
      EvaluationConstants.SINGLE_QUOTE + "CREValidationValue_"
          + EvaluationConstants.BOOLEAN_STRING_TRUE + EvaluationConstants.SINGLE_QUOTE;
  private static String[] illegalExpressionSymbols = {"=", "@", "#", "$", "^", "~", "`", "?", "\\"};

  public static String trimAndRemoveQuoteCharsIfNeed(final String input, final char quoteCharacter)
      throws FunctionException {
    String trimedValue = input.trim();
    if (trimedValue.charAt(0) == quoteCharacter
        && trimedValue.charAt(trimedValue.length() - 1) == quoteCharacter) {
      trimedValue = FunctionHelper.trimAndRemoveQuoteChars(trimedValue, quoteCharacter);
    }

    return trimedValue;
  }

  public static boolean isDouble(final String input) {
    try {
      Double.parseDouble(input);
    } catch (NumberFormatException ex) {
      return false;
    }
    return true;
  }

  public static String resolveBooleanVariable(final String variableName) {
    if (variableName.equals("true") || variableName.equals("TRUE")) {
      return EvaluationConstants.BOOLEAN_STRING_TRUE;
    }
    if (variableName.equals("false") || variableName.equals("FALSE")) {
      return EvaluationConstants.BOOLEAN_STRING_FALSE;
    }

    return null;
  }

  public static String supportArraysInExpression(String expression) {
    String formatedExpression = expression;
    int startIndex = 0;
    do {
      startIndex = formatedExpression.indexOf(openBracketCharacter, startIndex);
      if (startIndex >= 0) {
        int endIndex = formatedExpression.indexOf(closeBracketCharacter, startIndex + 1);
        if (endIndex > 0) {
          String arrayString = formatedExpression.substring(startIndex, endIndex + 1);
          arrayString = String.format("'%s'", arrayString.replace(',', ';'));
          formatedExpression = formatedExpression.substring(0, startIndex) + arrayString
              + formatedExpression.substring(endIndex + 1);
          endIndex += 3;
        }
        startIndex = endIndex;
      }
    } while (startIndex > 0);
    return formatedExpression;
  }

  // Helpers for validation expression usage
  public static String validationCheckSpecialCharsInVariable(String variable)
      throws EvaluationException {
    for (String illegalOperator : illegalExpressionSymbols) {
      int index = variable.indexOf(illegalOperator, 0);
      while (index >= 0) {
        if (illegalOperator.charAt(0) == EvaluationConstants.POUND_SIGN
            && variable.length() > (index + 1)
            && variable.charAt(index + 1) == EvaluationConstants.OPEN_BRACE) {
          index = variable.indexOf(illegalOperator, index + 1);
          continue; // skip legal variables start point
        }
        index++;
        throw new EvaluationException("Expression operator '" + illegalOperator
            + "' is not allowed in expression at " + index + ": " + variable);
      }
    }
    return null;
  }

  public static String validationTryReplaceArrayVariable(String variable) {
    String replaceValue =
        openBracketCharacter + EvaluationConstants.BOOLEAN_STRING_TRUE + closeBracketCharacter;
    if (variable.equals(EvaluatorHelpers.VALIDATION_VARIABLE_VALUE)) {
      return replaceValue;
    }

    return replaceExpressionVariableWithValue(variable, EvaluationConstants.OPEN_VARIABLE,
        EvaluationConstants.CLOSED_VARIABLE, replaceValue);
  }

  public static String validationReplaceIfStringValue(String expression, String replaceValue) {
    return replaceExpressionVariableWithValue(expression, EvaluationConstants.SINGLE_QUOTE + "",
        EvaluationConstants.SINGLE_QUOTE + "", replaceValue);
  }

  public static String validationReplaceIfSingleVariable(String expression, String replaceValue) {
    int index = expression.indexOf(EvaluationConstants.FUNCTION_ARGUMENT_SEPARATOR, 0);
    if (index >= 0) {
      return null;
    }
    return replaceExpressionVariableWithValue(expression, EvaluationConstants.OPEN_VARIABLE,
        EvaluationConstants.CLOSED_VARIABLE, replaceValue);
  }

  private static String replaceExpressionVariableWithValue(String expression, String begin,
      String end, String replaceValue) {
    String formatedExpression = expression;
    int startIndex = expression.indexOf(begin, 0);
    if (startIndex == 0) {
      startIndex += begin.length();
      int endIndex = formatedExpression.indexOf(end, startIndex);
      if (endIndex > startIndex && endIndex == (expression.length() - end.length())) {
        return replaceValue;
      }
    }

    return null;
  }

  // JEval evaluator exception
  public static String getDetailedMessage(EvaluationException ex) {
    String message = null;
    if (ex != null) {
      message = ex.getMessage();
      Throwable cause = ex.getCause();
      String causeMessage = "";
      while (cause != null) {
        causeMessage = cause.getMessage();
        cause = cause.getCause();
      }
      if (!message.equals(causeMessage)) {
        message += " " + causeMessage;
      }
    }

    return message;
  }
}
