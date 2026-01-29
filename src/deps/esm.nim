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

func fromProcDef(node: NimNode): string =
  case node[0].kind
  of nnkIdent:
    result = $node[0]
  of nnkPostFix:
    result = $node[0][1]
  else:
    error fmt("unexpected node kind {node[0].kind} for proc must be an ident or ident*")

func nameFromTypeDef(node: NimNode): string =
  expectKind node, nnkTypeDef
  case node[0].kind:
  of nnkIdent:
    result = $node[0]
  of nnkPragmaExpr:
    result = $node[0][0]
            #     |  ^ ident
            #     ^ PragmaExpr
  else: assert false

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
  of nnkProcDef:
    let name = fromProcDef(node)
    let importName =
      if defaultImport: newLit name
      else: importSet name
    result.add newImportEmit(importName, moduleName)
  of nnkStmtList:
    for stmt in node:
      result.add toImportStmts(stmt, moduleName, defaultImport)
  of nnkTypeSection:
    for t in node:
      result.add toImportStmts(t, moduleName, defaultImport)
  of nnkTypeDef:
    let name = nameFromTypeDef(node)
    let importName = if defaultImport: newLit(name) else: importSet(name)
    result.add newImportEmit(importName,moduleName)
  else:
    error fmt("unexpected node kind {node.kind} for target")

macro esm*(module: untyped, target: untyped): untyped =
  ## generate ES module import statemets
  expectKind module, {nnkIdent, nnkStrLit}
  var defaultImport = false
  var moduleName = module.strVal.newLit

  if ($module).startsWith("default:"):
    if target.kind notin {nnkProcDef, nnkTypeDef, nnkStmtList}:
      error "default:{module} only supported for procs and types"
    moduleName = newLit ($module)[8..^1]
    defaultImport = true
  result = newStmtList()
  result.add toImportStmts(target, moduleName, defaultImport)

  case target.kind
  of nnkProcDef:
    result.add target
  of nnkStmtList:
    for stmt in target:
      result.add stmt
  else: discard


