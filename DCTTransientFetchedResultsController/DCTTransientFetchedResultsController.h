//
//  DCTTransientFetchedResultsController.h
//  DCTTransientFetchedResultsController
//
//  Created by Daniel Tull on 13.01.2012.
//  Copyright (c) 2012 Daniel Tull Limited. All rights reserved.
//

@import CoreData;

@interface DCTTransientFetchedResultsController : NSFetchedResultsController

- (id)initWithFetchRequest:(NSFetchRequest *)fetchRequest 
	  managedObjectContext:(NSManagedObjectContext *)context
		sectionNameKeyPath:(NSString *)sectionNameKeyPath
				 cacheName:(NSString *)name 
		transientPredicate:(NSPredicate *)transientPredicate;

@property (nonatomic, readonly) NSPredicate *transientPredicate;

@end
