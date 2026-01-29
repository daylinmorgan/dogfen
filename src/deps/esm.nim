import std/[macros, strutils,strformat]

func newImportEmit(identifiers: NimNode, moduleName: NimNode): NimNode =
  expectKind identifiers, nnkStrLit
  expectKind moduleName, nnkStrLit
  nnkPragma.newTree(
    nnkExprColonExpr.newTree(
        newIdentNode("emit"),
        newLit(fmt"import {identifiers} from '{moduleName}';")),
      )

func importSet(names: varargs[string]): NimNode =
  newLit "{" & names.join(",") & "}"

func fromCurly(node: NimNode): NimNode =
  expectKind node, nnkCurly
  var names: seq[string]
  for n in node:
    expectKind n, {nnkIdent, nnkStrLit}
    names.add n.strVal
  importSet names


proc toImportStmts(node: NimNode, moduleName: NimNode, defaultImport: bool): seq[NimNode] =
  case node.kind
  of nnkIdent, nnkStrLit:
    result.add newImportEmit(newLit($node), moduleName)
  of nnkCurly:
    result.add newImportEmit(fromCurly(node), moduleName)
  of nnkProcDef, nnkTypeDef, nnkIdentDefs:
    let name = $node[0].basename
    let importName = if defaultImport: newLit name else: importSet name
    result.add newImportEmit(importName, moduleName)
  of nnkStmtList:
    for stmt in node:
      result.add toImportStmts(stmt, moduleName, defaultImport)
  of nnkTypeSection, nnkLetSection, nnkVarSection:
    for t in node:
      result.add toImportStmts(t, moduleName, defaultImport)
  else:
    error fmt("don't know how to get name from {node.kind} for target:\n {repr node}")


const defaultSpecKinds = {nnkProcDef, nnkTypeDef, nnkIdentDefs, nnkStmtList, nnkLetSection, nnkVarSection}

macro esm*(module: untyped, target: untyped): untyped =
  ## generate ES module import statemets
  expectKind module, {nnkIdent, nnkStrLit}
  var defaultImport = false
  var moduleName = module.strVal.newLit

  if ($module).startsWith("default:"):
    if target.kind notin defaultSpecKinds:
      error "default:{module} only supported for\n" & $defaultSpecKinds & "\ngot " & $target.kind
    moduleName = newLit ($module)[8..^1]
    defaultImport = true
  result = newStmtList()
  result.add toImportStmts(target, moduleName, defaultImport)

  case target.kind
  of nnkProcDef, nnkLetSection, nnkVarSection:
    result.add target
  of nnkStmtList:
    for stmt in target:
      result.add stmt
  else: discard

