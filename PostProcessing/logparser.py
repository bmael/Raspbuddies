#!/usr/bin/python3
# -*- coding: utf-8 -*-	

from collections import deque

class QVV:
	def __init__(self, vectorClock, kentries):
		self.vectorClock = tuple(vectorClock)
		self.kentries = list(kentries)
	
	def isDirectlyCausal(self, other):
		if len(self.vectorClock) != len(other.vectorClock):
			raise ValueError("size of QVVs are not equals")
		
		parent = [i for i in self.vectorClock]
		for k in self.kentries:
			parent[k] -= 1
		
		return tuple(parent) == other.vectorClock
			
	def __hash__(self):
		return hash(self.vectorClock)
	
	def __len__(self):
		return len(self.vectorClock)
	
	def __eq__(self, other):
		return self.vectorClock == other.vectorClock
		
	def __repr__(self):
		return repr(self.vectorClock)
		
class LogEntry:
	def __init__(self, sourceId, vectorClock, kentries, messageId, error):
		self.sourceId = sourceId
		self.qvv = QVV(vectorClock, kentries)
		self.messageId = messageId
		self.error = error
	
	def __repr__(self):
		return "{} - {} - {} - {}".format(self.sourceId, self.qvv,\
		self.messageId, self.error)

class LogParser:
	FIELD_SEPARATOR = '|'
	VECTOR_CLOCK_SEPARATOR = ','

	def parse(self, filename):
		logEntries = []
		
		with open(filename, 'r') as log:
			for line in log:
				fields = line.split(LogParser.FIELD_SEPARATOR)
				sourceId = int(fields[0].strip())
				vectorClock = fields[1].split(LogParser.VECTOR_CLOCK_SEPARATOR)
				vectorClock = [int(i) for i in vectorClock]
				kentries = fields[2].split(LogParser.VECTOR_CLOCK_SEPARATOR)
				kentries = [int(i) for i in kentries]
				messageId = fields[3].strip()
				error =  fields[4].strip() == '1'
				logEntries.append(LogEntry(sourceId, vectorClock, kentries,\
				messageId, error))
		
		return logEntries

class Vertex:
	def __init__(self, content):
		self.visited = False
		self.content = content
	
	def __str__(self):
		return str(self.content)
	
	def __repr__(self):
		return repr(self.content)
	
	def __hash__(self):
		return hash(self.content)
	
	def __eq__(self, other):
		return self.content == other.content

class Graph:
	def __init__(self):
		self.vertices = {}
	
	def __len__(self):
		return len(self.vertices)
	
	def __contains__(self, vertex):
		return vertex in self.vertices
	
	def addVertex(self, vertex):
		self.vertices[vertex] = []
	     
	def next(self, vertex):         
		if vertex not in self.vertices:
			raise KeyError("Vertex {0} not found".format(vertex))
            
		else:
			return self.vertices[vertex]
     
	def addEdge(self, start, end):
		if start not in self.vertices:
			self.vertices[start] = [end]
    	
		else:
			self.vertices[start].append(end)
    
	def __iter__(self):
		return iter(self.vertices)
	
	def reset(self):
		for vertex in self.vertices:
			vertex.visited = False
	
	def printy(self):
		for vertex in self.vertices:
			print("{}".format(vertex))
		
			for next in self.vertices[vertex]:
				print("--> {}".format(next))
		
	def isPathExist(self, start, end):
		self.reset()		
		queue = deque()
		start.visited = True
		queue.append(start)
		pathFound = False
		
		while not pathFound and len(queue) > 0:
			vertex = queue.popleft()
			pathFound = vertex == end
			
			if not pathFound:
				for next in self.vertices[vertex]:
					if not next.visited:
						next.visited = True
						queue.append(next)
		
		return pathFound
	
class GraphLogBuilder:
	def build(self, logEntries):
		if len(logEntries) == 0:
			raise ValueError("Empty log")
	
		graphLog = Graph()
		start = QVV(tuple([0] * len(logEntries[0].qvv)), ())
		graphLog.addVertex(Vertex(start))
		withoutParents = []
	
		for entry in logEntries:
			parentFound = False
			newVertex = Vertex(entry.qvv)
		
			# Find the parents 
			for vertex in graphLog:
				if entry.qvv.isDirectlyCausal(vertex.content):
					graphLog.addEdge(vertex, newVertex)
					parentFound = True
			
			graphLog.addVertex(newVertex)
		
			if not parentFound:
				withoutParents.append(newVertex)
	
		# Retry for the nodes without parent
		for withoutParent in withoutParents:
			for vertex in graphLog:
				if withoutParent.content.isDirectlyCausal(vertex.content):
					graphLog.addEdge(vertex, withoutParent)
	
		return graphLog

class LogAnalyzer:
	def __init__(self, logEntries):
		self.logEntries = logEntries
		self.errors = []
	
	def analyze(self):
		del self.errors[:]
		graphLogBuilder = GraphLogBuilder()
		graphLog = graphLogBuilder.build(self.logEntries)
		
		for i, entry in enumerate(self.logEntries):
			if entry.error:
				concurrents = []
				causals = []
				start = Vertex(entry.qvv)
				j = i - 1
				
				while not self.logEntries[j].qvv.isDirectlyCausal(entry.qvv):
					end = Vertex(self.logEntries[j].qvv)
					
					if graphLog.isPathExist(start, end):
						causals.append(self.logEntries[j])
					
					else:
						concurrents.append(self.logEntries[j])
					
					j -= 1
				
				self.logEntries.pop(i)
				self.logEntries.insert(j, entry)
				
				# Replace concurents operations
				for concurrent in concurrents:
					self.logEntries.remove(concurrent)
					self.logEntries.insert(j, concurrent)
				
				# Save statistics
				self.errors.append((len(causals), len(concurrents)))

def printLog(log):
	for entry in log:
		print(entry)	
			
try:
	logParser = LogParser()
	logEntries = logParser.parse('log1')
	printLog(logEntries)
	analyzer = LogAnalyzer(logEntries)
	analyzer.analyze()
	print("\nAFTER ANALYZE\n")
	printLog(logEntries)
	print("\nSTATS\n")
	print(analyzer.errors)

except IOError as e:
	print(e)
